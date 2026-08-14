-- models/marts/reporting/mart_top_performers.sql
-- Grain: entity_type + period_type + entity_id (top 3 per group by GMV)

with last_month as (

    select month_start
    from (
        select
            date_trunc(date(order_purchase_timestamp), month) as month_start,
            count(*) as orders_cnt
        from {{ ref('fct_orders') }}
        group by 1
    ) monthly_counts
    where orders_cnt >= 100
    order by month_start desc
    limit 1

),

-- PRODUCTS ------------------------------------------------

products_base as (

    select
        oi.product_key,
        p.product_category_name_english as entity_name,
        oi.price,
        date_trunc(date(o.order_purchase_timestamp), month) as month_start

    from {{ ref('fct_order_items') }} oi
    inner join {{ ref('fct_orders') }} o on oi.order_id = o.order_id
    left join {{ ref('dim_products') }} p on oi.product_key = p.product_key
    where oi.product_key is not null

),

products_current as (
    select
        'product' as entity_type,
        'current_month' as period_type,
        product_key as entity_id,
        coalesce(entity_name, 'Uncategorized') as entity_name,
        sum(price) as gmv
    from products_base b, last_month lm
    where b.month_start = lm.month_start
    group by 1,2,3,4
),

products_all_time as (
    select
        'product' as entity_type,
        'all_time' as period_type,
        product_key as entity_id,
        coalesce(entity_name, 'Uncategorized') as entity_name,
        sum(price) as gmv
    from products_base
    group by 1,2,3,4
),

-- SELLERS -------------------------------------------------

sellers_base as (

    select
        oi.seller_key,
        oi.price,
        date_trunc(date(o.order_purchase_timestamp), month) as month_start

    from {{ ref('fct_order_items') }} oi
    inner join {{ ref('fct_orders') }} o on oi.order_id = o.order_id
    where oi.seller_key is not null

),

sellers_current as (
    select
        'seller' as entity_type,
        'current_month' as period_type,
        seller_key as entity_id,
        seller_key as entity_name,
        sum(price) as gmv
    from sellers_base b, last_month
    where b.month_start = last_month.month_start
    group by 1,2,3,4
),

sellers_all_time as (
    select
        'seller' as entity_type,
        'all_time' as period_type,
        seller_key as entity_id,
        seller_key as entity_name,
        sum(price) as gmv
    from sellers_base
    group by 1,2,3,4
),

-- REGIONS (по customer_state, откуда идут продажи) ---------

regions_base as (

    select
        c.customer_state,
        oi.price,
        date_trunc(date(o.order_purchase_timestamp), month) as month_start

    from {{ ref('fct_order_items') }} oi
    inner join {{ ref('fct_orders') }} o on oi.order_id = o.order_id
    left join {{ ref('dim_customers') }} c on o.customer_key = c.customer_key
    where c.customer_state is not null

),

regions_current as (
    select
        'region' as entity_type,
        'current_month' as period_type,
        customer_state as entity_id,
        customer_state as entity_name,
        sum(price) as gmv
    from regions_base b, last_month
    where b.month_start = last_month.month_start
    group by 1,2,3,4
),

regions_all_time as (
    select
        'region' as entity_type,
        'all_time' as period_type,
        customer_state as entity_id,
        customer_state as entity_name,
        sum(price) as gmv
    from regions_base
    group by 1,2,3,4
),

-- UNION + RANK ----------------------------------------------

unioned as (
    select * from products_current
    union all select * from products_all_time
    union all select * from sellers_current
    union all select * from sellers_all_time
    union all select * from regions_current
    union all select * from regions_all_time
),

ranked as (
    select
        *,
        row_number() over (
            partition by entity_type, period_type
            order by gmv desc
        ) as rank

    from unioned
)

select
    {{ dbt_utils.generate_surrogate_key(['entity_type', 'period_type', 'entity_id']) }} as top_performer_key,
    entity_type,
    period_type,
    entity_id,
    entity_name,
    round(gmv, 2) as gmv,
    rank

from ranked
where rank <= 3
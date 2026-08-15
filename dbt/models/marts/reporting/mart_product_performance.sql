-- models/marts/reporting/mart_product_performance.sql
-- Grain: one row per category x month (full grid via dim_dates, no gaps)
-- Orphans are in 'Uncategorized'

with date_bounds as (

    select
        min(order_purchase_timestamp) as min_date,
        max(order_purchase_timestamp) as max_date
    from {{ ref('fct_orders') }}

),

months as (

    select distinct
        date_trunc(d.date_day, month) as month_start
    from {{ ref('dim_dates') }} d, date_bounds b
    where d.date_day between date(b.min_date) and date(b.max_date)

),

categories as (

    select distinct
        coalesce(product_category_name_english, 'Uncategorized') as category_name
    from {{ ref('dim_products') }}

),

grid as (
    select
        m.month_start,
        c.category_name
    from months m
    cross join categories c

),

sales as (

    select
        date_trunc(date(o.order_purchase_timestamp), month) as month_start,
        coalesce(p.product_category_name_english, 'Uncategorized') as category_name,
        sum(oi.price) as gmv,
        count(distinct oi.order_id) as orders_count,
        count(*) as items_sold

    from {{ ref('fct_order_items') }} oi
    inner join {{ ref('fct_orders') }} o on oi.order_id = o.order_id
    left join {{ ref('dim_products') }} p on oi.product_key = p.product_key
    group by 1, 2

),

joined as (

    select
        g.month_start,
        g.category_name,
        coalesce(s.gmv, 0) as gmv,
        coalesce(s.orders_count, 0) as orders_count,
        coalesce(s.items_sold, 0) as items_sold

    from grid g
    left join sales s
        on g.month_start = s.month_start
        and g.category_name = s.category_name

)

select
    {{ dbt_utils.generate_surrogate_key(['month_start', 'category_name']) }} as product_performance_key,
    month_start,
    category_name,
    gmv,
    round(
        safe_divide(gmv, lag(gmv) over (partition by category_name order by month_start)) - 1
    , 4) as gmv_growth_mom,
    orders_count,
    items_sold

from joined
order by month_start, category_name
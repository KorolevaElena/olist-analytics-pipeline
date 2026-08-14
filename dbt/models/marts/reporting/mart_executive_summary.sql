-- models/marts/reporting/mart_executive_summary.sql
-- Grain: one row per calendar month (no gaps within actual data range)

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

orders_monthly as (

    select
        date_trunc(date(order_purchase_timestamp), month) as month_start,
        count(distinct order_id) as orders_count,
        sum(order_value_products) as gmv,
        countif(order_status = 'canceled') as cancelled_count,
        countif(delay_delivery_hours is not null and delay_delivery_hours <= 0) as on_time_count,
        countif(delay_delivery_hours is not null) as delivered_count

    from {{ ref('fct_orders') }}
    group by 1

),

sellers_monthly as (

    select
        date_trunc(date(order_purchase_timestamp), month) as month_start,
        count(distinct seller_key) as active_sellers

    from {{ ref('fct_order_items') }}
    where seller_key is not null
    group by 1

),

reviews_monthly as (

    select
        date_trunc(date(order_purchase_timestamp), month) as month_start,
        avg(r.review_score) as avg_review_score

    from {{ ref('fct_reviews') }} r
    inner join {{ ref('fct_orders') }} o
        on r.order_id = o.order_id
    group by 1

),

customer_months as (
    select distinct
        customer_key,
        date_trunc(date(order_purchase_timestamp), month) as month_start,
    from {{ ref('fct_orders') }}
    where customer_key is not null

),

customer_retention_flag as (
    select
        cm.month_start,
        cm.customer_key,
        exists (
            select 1
            from customer_months cm_prev
            where cm_prev.customer_key = cm.customer_key
              and cm_prev.month_start between date_sub(cm.month_start, interval 3 month)
                                          and date_sub(cm.month_start, interval 1 month)
        ) as is_returning

    from customer_months cm

),

retention_monthly as (

    select
        month_start,
        count(distinct customer_key) as active_customers,
        safe_divide(countif(is_returning), count(*)) as retention_rate_3m

    from customer_retention_flag
    group by 1

),

joined as (

    select
        m.month_start,
        coalesce(om.gmv, 0) as gmv,
        coalesce(om.orders_count, 0) as orders_count,
        safe_divide(om.gmv, om.orders_count) as aov,
        safe_divide(om.cancelled_count, om.orders_count) as cancelled_rate,
        safe_divide(om.on_time_count, om.delivered_count) as on_time_rate,
        coalesce(sm.active_sellers, 0) as active_sellers,
        coalesce(rm.active_customers, 0) as active_customers,
        rm.retention_rate_3m,
        rev.avg_review_score

    from months m
    left join orders_monthly om on m.month_start = om.month_start
    left join sellers_monthly sm on m.month_start = sm.month_start
    left join retention_monthly rm on m.month_start = rm.month_start
    left join reviews_monthly rev on m.month_start = rev.month_start

)

select
    {{ dbt_utils.generate_surrogate_key(['month_start']) }} as month_key,
    month_start,
    gmv,
    round(safe_divide(gmv, lag(gmv) over (order by month_start)) - 1, 4) as gmv_growth_mom,
    orders_count,
    round(safe_divide(orders_count, lag(orders_count) over (order by month_start)) - 1, 4) as orders_growth_mom,
    round(aov, 2) as aov,
    active_sellers,
    active_customers,
    round(retention_rate_3m, 4) as retention_rate_3m,
    round(cancelled_rate, 4) as cancelled_rate,
    round(on_time_rate, 4) as on_time_rate,
    round(avg_review_score, 2) as avg_review_score

from joined
order by month_start
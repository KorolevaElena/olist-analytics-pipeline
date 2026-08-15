-- models/marts/reporting/mart_customer_analysis.sql
-- Grain: one row per customer
-- customer_status is checked based on the last available month purchases

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

customers as (

    select
        customer_key,
        customer_unique_id,
        customer_state,
        first_order_date,
        last_order_date

    from {{ ref('dim_customers') }}

)

select
    c.customer_key,
    c.customer_state,
    c.first_order_date,
    c.last_order_date,

    case
        when date_trunc(date(c.first_order_date), month) = lm.month_start
            then 'new'
        when date(c.last_order_date) >= date_sub(date(lm.month_start), interval 3 month)
            then 'active'
        else 'inactive'
    end as customer_status

from customers c
cross join last_month lm
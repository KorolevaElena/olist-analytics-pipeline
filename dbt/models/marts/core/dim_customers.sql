-- models/marts/core/dim_customers.sql
-- Grain: one row per customer_unique_id
-- Address of customer: defined based on last available purchase => no need to keep full history

with orders as (

    select
        customer_id,
        order_purchase_timestamp

    from {{ ref('stg_orders') }}

),

customers as (

    select
        customer_id,
        customer_unique_id,
        customer_city,
        customer_state,
        customer_zip_code_prefix

    from {{ ref('stg_customers') }}

),

customer_orders as (

    select
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        c.customer_zip_code_prefix,
        o.order_purchase_timestamp,

        row_number() over (
            partition by c.customer_unique_id
            order by o.order_purchase_timestamp desc
        ) as rn_latest

    from customers c
    inner join orders o
        on c.customer_id = o.customer_id

),

customer_dates as (

    select
        customer_unique_id,
        min(order_purchase_timestamp) as first_order_date,
        max(order_purchase_timestamp) as last_order_date

    from customer_orders
    group by customer_unique_id

),

latest_address as (

    select
        customer_unique_id,
        customer_city,
        customer_state,
        customer_zip_code_prefix

    from customer_orders
    where rn_latest = 1

)

select
    {{ dbt_utils.generate_surrogate_key(['la.customer_unique_id']) }} as customer_key,
    la.customer_unique_id,
    la.customer_city,
    la.customer_state,
    la.customer_zip_code_prefix,
    cd.first_order_date,
    cd.last_order_date

from latest_address la
inner join customer_dates cd
    on la.customer_unique_id = cd.customer_unique_id
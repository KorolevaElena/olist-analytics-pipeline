-- models/marts/core/fct_orders.sql
-- Grain: one row per order with delivery and price info

with order_items as (

    select
        order_id,
        sum(price) as order_value_products,
        sum(freight_value) as delivery_value,
        sum(price) + sum(freight_value) as total_value

    from {{ ref('fct_order_items') }}
    group by order_id

),

orders as (

    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date

    from {{ ref('stg_orders') }}

),

customers as (

    select
        customer_id,
        customer_unique_id

    from {{ ref('stg_customers') }}

),

dim_customers as (

    select
        customer_key,
        customer_unique_id

    from {{ ref('dim_customers') }}

),

joined as (

    select
        oi.order_id,
        oi.order_value_products,
        oi.delivery_value,
        oi.total_value,
        dc.customer_key,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        o.order_status,

        timestamp_diff(o.order_approved_at, o.order_purchase_timestamp, hour) as approval_time_hours,
        timestamp_diff(o.order_delivered_carrier_date, o.order_approved_at, hour) as dispatch_time_hours,
        timestamp_diff(o.order_delivered_customer_date, o.order_delivered_carrier_date, hour) as transit_time_hours,
        timestamp_diff(o.order_delivered_customer_date, o.order_estimated_delivery_date, hour) as delay_delivery_hours

    from order_items oi
    left join orders o
        on oi.order_id = o.order_id
    left join customers c
        on o.customer_id = c.customer_id
    left join dim_customers dc
        on c.customer_unique_id = dc.customer_unique_id

)

select
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_key,
    order_id,
    order_value_products,
    delivery_value,
    total_value,
    customer_key,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    order_status,
    approval_time_hours,
    dispatch_time_hours,
    transit_time_hours,
    delay_delivery_hours

from joined
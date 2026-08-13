-- models/marts/core/fct_order_items.sql
-- Grain: one row per order_item (order_id + order_item_id)

with order_items as (

    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        price,
        freight_value

    from {{ ref('stg_order_items') }}

),

orders as (

    select
        order_id,
        customer_id,
        order_purchase_timestamp

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

dim_products as (

    select
        product_key,
        product_id

    from {{ ref('dim_products') }}

),

dim_sellers as (

    select
        seller_key,
        seller_id

    from {{ ref('dim_sellers') }}

),

joined as (

    select
        oi.order_id,
        oi.order_item_id,
        dc.customer_key,
        dp.product_key,
        ds.seller_key,
        o.order_purchase_timestamp,
        oi.price,
        oi.freight_value

    from order_items oi
    left join orders o
        on oi.order_id = o.order_id
    left join customers c
        on o.customer_id = c.customer_id
    left join dim_customers dc
        on c.customer_unique_id = dc.customer_unique_id
    left join dim_products dp
        on oi.product_id = dp.product_id
    left join dim_sellers ds
        on oi.seller_id = ds.seller_id

)

select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_key,
    order_id,
    order_item_id,
    customer_key,
    product_key,
    seller_key,
    order_purchase_timestamp,
    price,
    freight_value

from joined
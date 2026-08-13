-- models/marts/core/fct_order_payments.sql
-- Grain: one row per one type of payment

with order_payments as (

    select
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value

    from {{ ref('stg_order_payments') }}

),

orders as (

    select
        order_id,
        order_key

    from {{ ref('fct_orders') }}

),

joined as (

    select
        op.order_id,
        o.order_key,
        op.payment_sequential,
        op.payment_installments,
        op.payment_type,
        op.payment_value

    from order_payments op
    left join orders o
        on op.order_id = o.order_id

)

select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }} as order_payment_key,
    order_id,
    order_key,
    payment_sequential,
    payment_installments,
    payment_type,
    payment_value

from joined
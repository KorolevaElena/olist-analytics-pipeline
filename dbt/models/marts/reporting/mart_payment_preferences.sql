-- models/marts/reporting/mart_payment_preferences.sql
-- Grain: one row per customer_state, status, payment_type


with customers as (

    select 
        customer_key,
        customer_state,
        customer_status
    from {{ ref('mart_customer_analysis') }}

),

payments as (
    select
        order_payment_key,
        order_id,
        order_key,
        payment_type,
        payment_sequential,
        payment_installments,
        payment_value
    from {{ ref('fct_order_payments') }}
),

orders_cutsomers as (
    select
        order_key,
        customer_key
    from {{ ref('fct_orders') }} 
),

join_orders as (
    select
        p.order_payment_key,
        p.order_key,
        oc.customer_key,
        p.payment_type,
        p.payment_sequential,
        p.payment_installments,
        p.payment_value
    from payments p
    inner join orders_cutsomers oc on oc.order_key=p.order_key
)

select
        {{ dbt_utils.generate_surrogate_key(['customer_state', 'customer_status', 'payment_type']) }} as payment_pref_key,
        c.customer_state,
        c.customer_status,
        o.payment_type,
        count(distinct c.customer_key) as number_customers,
        count (distinct o.order_key) as count_orders,
        avg(o.payment_installments) as avg_installement,
        avg(o.payment_value) as avg_purchase
from join_orders o
inner join customers c on o.customer_key=c.customer_key
group by 1,2,3,4
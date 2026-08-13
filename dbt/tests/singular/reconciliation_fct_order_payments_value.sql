-- tests/singular/reconciliation_fct_order_payments_value.sql
-- checking if somewhere we multiplied rows, so sum will not be correct in the end

with stg_order_payments as (

    select sum(payment_value) as total_value
    from {{ ref('stg_order_payments') }}

),

fact_total as (

    select sum(payment_value) as total_value
    from {{ ref('fct_order_payments') }}

)

select
    s.total_value as total_stg_payment,
    f.total_value as total_fct_payment,
    abs(s.total_value - f.total_value) as diff

from stg_order_payments s
cross join fact_total f
where abs(s.total_value - f.total_value) > 0.01
-- tests/singular/reconciliation_fct_orders.sql
-- checking if somewhere we multiplied rows, so sum will not be correct in the end

with fct_order_items as (

    select sum(price) + sum(freight_value) as total_value
    from {{ ref('stg_order_items') }}

),

fact_total as (

    select sum(total_value) as total_value
    from {{ ref('fct_orders') }}

)

select
    s.total_value as total_fct_order_items,
    f.total_value as total_fct_order,
    abs(s.total_value - f.total_value) as diff

from fct_order_items s
cross join fact_total f
where abs(s.total_value - f.total_value) > 0.01
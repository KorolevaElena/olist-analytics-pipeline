-- tests/singular/reconciliation_fct_order_items_price.sql
-- checking if somewhere we multiplied rows, so sum will not be correct in the end

with staging_total as (

    select sum(price) as total_price
    from {{ ref('stg_order_items') }}

),

fact_total as (

    select sum(price) as total_price
    from {{ ref('fct_order_items') }}

)

select
    s.total_price as staging_total_price,
    f.total_price as fact_total_price,
    abs(s.total_price - f.total_price) as diff

from staging_total s
cross join fact_total f
where abs(s.total_price - f.total_price) > 0.01
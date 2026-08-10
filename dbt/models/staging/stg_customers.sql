-- Staging: customers. customer_id is unique per order,
-- while customer_unique_id identifies the real person (one person can
-- place multiple orders with different customer_id values but the same customer_unique_id)
select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
from {{ source('raw', 'customers') }}

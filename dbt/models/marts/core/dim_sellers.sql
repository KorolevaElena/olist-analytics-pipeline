-- models/marts/core/dim_sellers.sql
-- Grain: one row per seller_id

select
   {{ dbt_utils.generate_surrogate_key(['seller_id']) }} as seller_key,
   seller_id,
   seller_zip_code_prefix,
   seller_city,
   seller_state
from {{ ref('stg_sellers') }}
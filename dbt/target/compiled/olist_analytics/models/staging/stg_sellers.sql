-- Staging: sellers. Seller_id is unique primary key. Seller "address"
select
   seller_id,
   seller_zip_code_prefix,
   seller_city,
   seller_state
from `olist-analytics-pipeline`.`raw`.`sellers`


  create or replace view `olist-analytics-pipeline`.`staging`.`stg_products`
  OPTIONS()
  as -- Staging: products, physical characteristics of each product.
-- product_id is unique (primary key).
-- NOTE: source column is misspelled as "product_name_lenght" in raw data;
-- renamed here to the correct "product_name_length" so downstream
-- models/dashboards use proper naming.
-- KNOWN DATA QUALITY ISSUE: some products have null product_category_name
-- (orphan products) or null product_name_length (broken listing).
-- Both cases likely mean the product is not discoverable/purchasable
-- by customers. Rows are kept here for referential integrity with
-- order_items; filtering should happen in the marts layer where relevant.

select
    product_id,
    product_category_name,
    product_name_lenght as product_name_length,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,product_width_cm

from `olist-analytics-pipeline`.`raw`.`products`;


-- models/marts/reporting/mart_catalog_quality.sql
-- Grain: one row per product
-- checking orphans and product card

with products as (

    select
        product_key,
        product_category_name,
        product_category_name_english,
        product_name_length,
        product_description_length,
        product_photos_qty
    from {{ ref('dim_products') }}

)

select
    product_key,
    product_category_name_english as product_category_name,
    case when product_category_name is null then 1 else 0 end as is_orphan,
    case when product_category_name_english is null and product_category_name is not null then 1 else 0 end as missing_translation,
    case when product_name_length = 0 or product_name_length is null then 1 else 0 end as  is_no_name,
    case when product_description_length = 0 or product_description_length is null then 1 else 0 end as is_no_description,
    case when product_photos_qty = 0 or product_photos_qty is null then 1 else 0 end as is_no_photo,
    case when product_description_length < 50 and product_description_length is not null then  1 else 0 end as is_too_short_descr,
    case when product_photos_qty < 3 and product_photos_qty is not null then 1 else 0 end as is_not_enough_photo

from products
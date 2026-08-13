-- models/marts/core/dim_products.sql
-- Grain: one row per product_id
-- Keep all products with "issues" like orphans and not correctly named products

with translation as (

    select
        product_category_name,
        product_category_name_english

    from {{ ref('stg_category_translation') }}

),

products as (

    select
        product_id,
        product_category_name,
        product_name_length,
        product_description_lenght as product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm

    from {{ ref('stg_products') }}

)


select
    {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
    p.product_id,
    p.product_category_name,
    tr.product_category_name_english,
    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm

from products p
left join translation tr
    on tr.product_category_name = p.product_category_name
-- Staging: translation of product category names from Portuguese to English.
-- NOTE: source CSV has no header row, so BigQuery autodetect assigned
-- generic column names (string_field_0/1) at load time; renamed here
-- to meaningful names.

select
    string_field_0 as product_category_name,
    string_field_1 as product_category_name_english

from {{ source('raw', 'category_translation') }}

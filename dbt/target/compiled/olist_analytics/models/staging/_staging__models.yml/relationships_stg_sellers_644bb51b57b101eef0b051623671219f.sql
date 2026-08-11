
    
    

with child as (
    select seller_zip_code_prefix as from_field
    from `olist-analytics-pipeline`.`staging`.`stg_sellers`
    where seller_zip_code_prefix is not null
),

parent as (
    select geolocation_zip_code_prefix as to_field
    from `olist-analytics-pipeline`.`staging`.`stg_geolocation`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null




    
    

with child as (
    select customer_zip_code_prefix as from_field
    from `olist-analytics-pipeline`.`staging`.`stg_customers`
    where customer_zip_code_prefix is not null
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



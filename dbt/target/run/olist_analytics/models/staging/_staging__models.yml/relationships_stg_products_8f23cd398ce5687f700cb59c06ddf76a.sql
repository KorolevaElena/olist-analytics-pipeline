select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with child as (
    select product_category_name as from_field
    from `olist-analytics-pipeline`.`staging`.`stg_products`
    where product_category_name is not null
),

parent as (
    select product_category_name as to_field
    from `olist-analytics-pipeline`.`staging`.`stg_category_translation`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



      
    ) dbt_internal_test
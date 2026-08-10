select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select product_category_name
from `olist-analytics-pipeline`.`staging`.`stg_products`
where product_category_name is null



      
    ) dbt_internal_test
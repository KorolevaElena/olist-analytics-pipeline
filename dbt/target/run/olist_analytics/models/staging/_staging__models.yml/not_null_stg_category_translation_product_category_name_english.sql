select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select product_category_name_english
from `olist-analytics-pipeline`.`staging`.`stg_category_translation`
where product_category_name_english is null



      
    ) dbt_internal_test
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select customer_zip_code_prefix
from `olist-analytics-pipeline`.`staging`.`stg_customers`
where customer_zip_code_prefix is null



      
    ) dbt_internal_test
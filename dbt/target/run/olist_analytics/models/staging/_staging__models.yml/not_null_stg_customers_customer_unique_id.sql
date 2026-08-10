select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select customer_unique_id
from `olist-analytics-pipeline`.`staging`.`stg_customers`
where customer_unique_id is null



      
    ) dbt_internal_test
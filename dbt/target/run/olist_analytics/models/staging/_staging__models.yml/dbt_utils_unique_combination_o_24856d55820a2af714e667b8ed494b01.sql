select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      





with validation_errors as (

    select
        order_id, payment_sequential
    from `olist-analytics-pipeline`.`staging`.`stg_order_payments`
    group by order_id, payment_sequential
    having count(*) > 1

)

select *
from validation_errors



      
    ) dbt_internal_test
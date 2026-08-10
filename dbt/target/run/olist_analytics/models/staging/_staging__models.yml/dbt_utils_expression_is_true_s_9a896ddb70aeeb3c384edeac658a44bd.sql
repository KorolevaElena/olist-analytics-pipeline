select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      



select
    1
from `olist-analytics-pipeline`.`staging`.`stg_order_reviews`

where not(review_answer_timestamp >= review_creation_date)


      
    ) dbt_internal_test
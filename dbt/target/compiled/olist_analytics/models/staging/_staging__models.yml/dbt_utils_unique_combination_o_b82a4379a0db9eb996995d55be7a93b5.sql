





with validation_errors as (

    select
        order_id, review_id
    from `olist-analytics-pipeline`.`staging`.`stg_order_reviews`
    group by order_id, review_id
    having count(*) > 1

)

select *
from validation_errors



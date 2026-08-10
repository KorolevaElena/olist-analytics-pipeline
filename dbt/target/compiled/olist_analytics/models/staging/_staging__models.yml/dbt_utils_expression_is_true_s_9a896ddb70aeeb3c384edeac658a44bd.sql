



select
    1
from `olist-analytics-pipeline`.`staging`.`stg_order_reviews`

where not(review_answer_timestamp >= review_creation_date)


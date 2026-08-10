

  create or replace view `olist-analytics-pipeline`.`staging`.`stg_order_reviews`
  OPTIONS()
  as -- Staging: order reviews. NOTE: review_id is NOT guaranteed unique --
-- ~1% of reviews appear twice with identical content but different
-- order_id (likely a data export issue upstream, per Kaggle discussion).
-- We keep both rows rather than deduplicate, since we cannot determine
-- which order_id is "correct" without additional source information.
select
    order_id,
    review_id,
    cast(review_score AS INT64) as review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
from `olist-analytics-pipeline`.`raw`.`order_reviews`;


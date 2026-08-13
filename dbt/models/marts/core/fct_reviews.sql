-- models/marts/core/fct_reviews.sql
-- Grain: one row per review (order_id + review_id)


with reviews as (

    select
        order_id,
        review_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp

    from {{ ref('stg_order_reviews') }}

),

orders as (

    select
        order_id,
        order_key

    from {{ ref('fct_orders') }}

),

joined as (

    select
        r.order_id,
        r.review_id,
        o.order_key,
        r.review_score,
        r.review_comment_title,
        r.review_comment_message,
        r.review_creation_date,
        r.review_answer_timestamp

    from reviews r
    left join orders o
        on r.order_id = o.order_id

)

select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'review_id']) }} as review_key,
    order_id,
    review_id,
    order_key,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp

from joined
-- models/marts/reporting/mart_seller_performance.sql
-- Grain: one row per seller (snapshot as of last available data)
-- avg_review_score only for orders with 1 seller

with seller_orders as (

    select
        oi.seller_key,
        oi.order_id,
        oi.price,
        o.delay_delivery_hours,
        o.dispatch_time_hours,
        o.transit_time_hours,
        o.order_purchase_timestamp

    from {{ ref('fct_order_items') }} oi
    inner join {{ ref('fct_orders') }} o on oi.order_id = o.order_id
    where oi.seller_key is not null

),

seller_agg as (

    select
        seller_key,
        sum(price) as total_gmv,
        count(distinct order_id) as orders_count,
        avg(dispatch_time_hours) as avg_dispatch_time_hours,
        avg(transit_time_hours) as avg_transit_time_hours,
        avg(delay_delivery_hours) as avg_delay_hours,
        safe_divide(countif(delay_delivery_hours <= 0), countif(delay_delivery_hours is not null)) as on_time_rate,
        max(date_trunc(date(order_purchase_timestamp), month)) >=
            date_sub((select max(date_trunc(date(order_purchase_timestamp), month)) from {{ ref('fct_orders') }}), interval 3 month)
            as is_active

    from seller_orders
    group by seller_key

),

single_seller_orders as (
    select order_id
    from {{ ref('fct_order_items') }}
    where seller_key is not null
    group by order_id
    having count(distinct seller_key) = 1

),

seller_reviews as (

    select
        oi.seller_key,
        avg(r.review_score) as avg_review_score

    from {{ ref('fct_reviews') }} r
    inner join single_seller_orders sso on r.order_id = sso.order_id
    inner join {{ ref('fct_order_items') }} oi on r.order_id = oi.order_id
    group by oi.seller_key

),

seller_catalog as (

    select
        oi.seller_key,
        avg(cq.is_no_photo) as pct_products_no_photo,
        avg(cq.is_orphan) as pct_products_no_category

    from {{ ref('fct_order_items') }} oi
    inner join {{ ref('mart_catalog_quality') }} cq on oi.product_key = cq.product_key
    where oi.seller_key is not null
    group by oi.seller_key

),

region_avg as (
    select
        d.seller_state,
        avg(sa.avg_delay_hours) as region_avg_delay_hours

    from seller_agg sa
    inner join {{ ref('dim_sellers') }} d on sa.seller_key = d.seller_key
    group by d.seller_state

)

select
    sa.seller_key,
    d.seller_state,
    sa.total_gmv,
    sa.orders_count,
    round(sa.avg_dispatch_time_hours, 1) as avg_dispatch_time_hours,
    round(sa.avg_transit_time_hours, 1) as avg_transit_time_hours,
    round(sa.avg_delay_hours, 1) as avg_delay_hours,
    round(ra.region_avg_delay_hours, 1) as region_avg_delay_hours,
    round(sa.on_time_rate, 4) as on_time_rate,
    sa.is_active,
    round(sr.avg_review_score, 2) as avg_review_score,
    round(sc.pct_products_no_photo, 4) as pct_products_no_photo,
    round(sc.pct_products_no_category, 4) as pct_products_no_category

from seller_agg sa
left join {{ ref('dim_sellers') }} d on sa.seller_key = d.seller_key
left join region_avg ra on d.seller_state = ra.seller_state
left join seller_reviews sr on sa.seller_key = sr.seller_key
left join seller_catalog sc on sa.seller_key = sc.seller_key
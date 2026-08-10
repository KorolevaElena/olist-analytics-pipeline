-- Staging: order line items. order_id is not unique
-- since one order can contain multiple items.

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value

from `olist-analytics-pipeline`.`raw`.`order_items`
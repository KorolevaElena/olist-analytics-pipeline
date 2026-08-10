

  create or replace view `olist-analytics-pipeline`.`staging`.`stg_orders`
  OPTIONS()
  as -- Staging-модель: 1:1 отражение raw.orders с явной типизацией
-- и понятными именами колонок. Никаких джойнов и агрегаций здесь.

select
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date

from `olist-analytics-pipeline`.`raw`.`orders`;




  create or replace view `olist-analytics-pipeline`.`staging`.`stg_order_payments`
  OPTIONS()
  as -- Staging: order payments. order_id is not unique since one order
-- can be paid using multiple payment methods (see payment_sequential)

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value

from `olist-analytics-pipeline`.`raw`.`order_payments`;


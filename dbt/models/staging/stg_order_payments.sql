-- Staging: order payments. order_id is not unique since one order
-- can be paid using multiple payment methods (see payment_sequential)

select
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value

from {{ source('raw', 'order_payments') }}

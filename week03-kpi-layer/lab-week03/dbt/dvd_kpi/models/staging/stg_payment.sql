select
    payment_id::integer as payment_id,
    customer_id::integer as customer_id,
    staff_id::integer as staff_id,
    rental_id::integer as rental_id,
    amount::numeric(12, 2) as amount,
    payment_date::timestamp as payment_date
from {{ source('dvdrental', 'payment') }}

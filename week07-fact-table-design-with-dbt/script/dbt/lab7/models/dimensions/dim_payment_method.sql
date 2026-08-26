select
    md5(payment_method) as payment_method_key,
    payment_method

from {{ ref('stg_orders_log') }}
group by payment_method

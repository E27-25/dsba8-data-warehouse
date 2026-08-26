select
    md5(customer_code) as customer_key,
    customer_code,
    max(customer_name) as customer_name

from {{ ref('stg_orders_log') }}
group by customer_code

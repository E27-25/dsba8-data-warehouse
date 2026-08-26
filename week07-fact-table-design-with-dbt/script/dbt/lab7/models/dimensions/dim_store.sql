select
    md5(store_code) as store_key,
    store_code,
    max(store_name) as store_name

from {{ ref('stg_orders_log') }}
group by store_code

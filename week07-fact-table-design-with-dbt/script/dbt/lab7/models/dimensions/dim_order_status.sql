select
    md5(status) as status_key,
    status

from {{ ref('stg_orders_log') }}
group by status

select
    md5(staff_code) as staff_key,
    staff_code,
    max(staff_name) as staff_name

from {{ ref('stg_orders_log') }}
group by staff_code

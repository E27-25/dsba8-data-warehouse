-- SCD Type 2: ลูกค้าหนึ่งคนต้องมีเวอร์ชันปัจจุบันเพียงหนึ่งเดียว
select
    customer_code,
    count(*) as current_versions
from {{ ref('dim_customer') }}
where is_current
group by customer_code
having count(*) <> 1

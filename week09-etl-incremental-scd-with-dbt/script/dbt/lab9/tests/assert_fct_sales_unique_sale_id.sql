-- Incremental Load ต้องไม่ทำให้เกิด sale_id ซ้ำหลังโหลด Batch 2
select
    sale_id,
    count(*) as row_count
from {{ ref('fct_sales') }}
group by sale_id
having count(*) > 1

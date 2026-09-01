-- ทุกจังหวัดในข้อมูลขายต้องหาเจอใน mapping ไม่งั้น dim_store จะตกสาขา
select distinct
    s.province
from {{ ref('stg_coffee_sales') }} s
left join {{ ref('stg_province_region') }} p
       on p.province_name = s.province
where p.province_name is null

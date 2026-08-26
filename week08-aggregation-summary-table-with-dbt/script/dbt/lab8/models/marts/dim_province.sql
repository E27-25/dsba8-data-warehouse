select distinct
    md5(m.province_name) as province_key,
    m.province_name,
    r.region_key
from {{ ref('stg_province_region_mapping') }} m
join {{ ref('dim_region') }} r
  on m.region_name = r.region_name

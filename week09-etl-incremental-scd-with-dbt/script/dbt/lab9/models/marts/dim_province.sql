{{ config(materialized='table') }}
select
  md5(p.province_name) as province_key,
  p.province_name,
  r.region_key
from {{ ref('stg_province_region') }} p
join {{ ref('dim_region') }} r on r.region_name=p.region_name

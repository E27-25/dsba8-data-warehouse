{{ config(materialized='table') }}
select distinct
  md5(s.store_code) as store_key,
  s.store_code, s.store_name, p.province_key
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_province') }} p on p.province_name=s.province

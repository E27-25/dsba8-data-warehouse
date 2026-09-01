{{ config(materialized='table') }}
select distinct
  md5(s.staff_code) as staff_key,
  s.staff_code, s.staff_name, p.position_key
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_position') }} p on p.position=s.position

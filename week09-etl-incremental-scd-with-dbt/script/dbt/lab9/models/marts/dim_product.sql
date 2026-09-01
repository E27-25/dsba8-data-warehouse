{{ config(materialized='table') }}
select distinct
  md5(concat_ws('|',s.product_code,s.size)) as product_key,
  s.product_code, s.product_name, c.category_key, s.size, s.unit_price
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_category') }} c on c.category_name=s.category

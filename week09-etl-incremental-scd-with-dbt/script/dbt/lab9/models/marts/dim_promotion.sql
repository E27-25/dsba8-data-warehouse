{{ config(materialized='table') }}
select distinct
  md5(promo_code) as promo_key, promo_code, promo_desc
from {{ ref('stg_coffee_sales') }}
where promo_code is not null

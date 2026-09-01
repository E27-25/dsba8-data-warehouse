with source as (select * from {{ ref('coffee_sales_scd_new') }})
select
  sale_id::bigint as sale_id, invoice_number, sale_date::date as sale_date,
  customer_code, customer_name, gender, birth_year::int as birth_year,
  province, product_code, product_name, category, size,
  unit_price::numeric(12,2) as unit_price, quantity::int as quantity,
  revenue::numeric(18,2) as revenue,
  store_code, store_name, staff_code, staff_name, position,
  nullif(promo_code,'') as promo_code,
  nullif(promo_desc,'') as promo_desc,
  coalesce(points_redeemed,0)::int as points_redeemed
from source

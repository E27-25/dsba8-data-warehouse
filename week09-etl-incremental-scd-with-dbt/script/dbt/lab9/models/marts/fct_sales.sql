{{
  config(
    materialized='incremental',
    unique_key='sale_id',
    incremental_strategy='merge'
  )
}}
select
  s.sale_id, s.invoice_number, d.date_key, c.customer_key,
  p.product_key, st.store_key, sf.staff_key, pr.promo_key,
  s.quantity, s.revenue, s.points_redeemed
from {{ ref('int_sales_batch') }} s
join {{ ref('dim_date') }} d on d.sale_date=s.sale_date
join {{ ref('dim_customer') }} c
  on c.customer_code=s.customer_code
 and s.sale_date between c.start_date and c.end_date
join {{ ref('dim_product') }} p on p.product_code=s.product_code and p.size=s.size
join {{ ref('dim_store') }} st on st.store_code=s.store_code
join {{ ref('dim_staff') }} sf on sf.staff_code=s.staff_code
left join {{ ref('dim_promotion') }} pr on pr.promo_code=s.promo_code
{% if is_incremental() %}
where not exists (
  select 1 from {{ this }} f where f.sale_id=s.sale_id
)
{% endif %}

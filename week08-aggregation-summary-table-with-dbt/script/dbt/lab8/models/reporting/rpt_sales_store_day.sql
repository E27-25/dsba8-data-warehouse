select
    d.sale_date,
    s.store_key,
    s.store_code,
    s.store_name,
    sum(f.revenue) as daily_revenue,
    sum(f.quantity) as daily_quantity,
    count(distinct f.invoice_number) as invoice_count
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }} d
  on f.date_key = d.date_key
join {{ ref('dim_store') }} s
  on f.store_key = s.store_key
group by
    d.sale_date,
    s.store_key,
    s.store_code,
    s.store_name

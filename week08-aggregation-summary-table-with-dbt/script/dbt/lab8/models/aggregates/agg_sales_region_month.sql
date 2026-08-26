{{
  config(
    indexes=[
      {'columns': ['month_start', 'region_key'], 'unique': true}
    ]
  )
}}

select
    date_trunc('month', d.sale_date)::date as month_start,
    r.region_key,
    r.region_name,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as total_quantity,
    sum(f.points_redeemed) as total_points_redeemed,
    count(distinct f.invoice_number) as invoice_count,
    count(*) as line_item_count
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }} d
  on f.date_key = d.date_key
join {{ ref('dim_store') }} s
  on f.store_key = s.store_key
join {{ ref('dim_province') }} p
  on s.province_key = p.province_key
join {{ ref('dim_region') }} r
  on p.region_key = r.region_key
group by
    date_trunc('month', d.sale_date)::date,
    r.region_key,
    r.region_name

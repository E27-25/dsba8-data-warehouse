select
    d.year,
    f.staff_key,
    grouping(d.year) as is_all_years,
    grouping(f.staff_key) as is_all_staff,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as total_quantity
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }} d
  on f.date_key = d.date_key
group by cube(d.year, f.staff_key)

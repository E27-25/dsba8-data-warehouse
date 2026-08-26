select
    date_trunc('quarter', month_start)::date as quarter_start,
    region_key,
    region_name,
    sum(total_revenue) as quarter_revenue,
    sum(total_quantity) as quarter_quantity,
    sum(total_points_redeemed) as quarter_points_redeemed,
    sum(invoice_count) as quarter_invoice_count
from {{ ref('agg_sales_region_month') }}
group by
    date_trunc('quarter', month_start)::date,
    region_key,
    region_name

with fact_total as (
    select
        sum(revenue) as revenue,
        sum(quantity) as quantity,
        sum(points_redeemed) as points
    from {{ ref('fct_sales') }}
),

summary_total as (
    select
        sum(total_revenue) as revenue,
        sum(total_quantity) as quantity,
        sum(total_points_redeemed) as points
    from {{ ref('agg_sales_region_month') }}
)

select
    f.revenue as fact_revenue,
    s.revenue as summary_revenue,
    f.quantity as fact_quantity,
    s.quantity as summary_quantity,
    f.points as fact_points,
    s.points as summary_points
from fact_total f
cross join summary_total s
where abs(f.revenue - s.revenue) > 0.01
   or f.quantity <> s.quantity
   or f.points <> s.points

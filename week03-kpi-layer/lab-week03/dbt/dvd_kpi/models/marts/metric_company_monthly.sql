with monthly_base as (
    select
        rental_month as metric_month,
        sum(revenue_amount) as total_revenue,
        sum(rental_count) as rental_count,
        count(distinct customer_id) as active_customer_count,
        sum(late_rental_count) as late_rental_count,
        sum(returned_rental_count) as returned_rental_count
    from {{ ref('fct_rental_activity') }}
    group by rental_month
),
metric_values as (
    select
        metric_month,
        'M001'::varchar as metric_key,
        total_revenue::numeric(18, 4) as metric_value
    from monthly_base
    union all
    select
        metric_month,
        'M002',
        rental_count::numeric(18, 4)
    from monthly_base
    union all
    select
        metric_month,
        'M003',
        active_customer_count::numeric(18, 4)
    from monthly_base
    union all
    select
        metric_month,
        'M004',
        (
            total_revenue
            / nullif(rental_count, 0)
        )::numeric(18, 4)
    from monthly_base
    union all
    select
        metric_month,
        'M005',
        (
            late_rental_count::numeric
            / nullif(returned_rental_count, 0)
        )::numeric(18, 4)
    from monthly_base
)
select
    v.metric_month,
    v.metric_key,
    d.metric_name,
    d.metric_label,
    d.description,
    d.formula,
    d.unit,
    v.metric_value
from metric_values v
join {{ ref('metric_definition') }} d
  on v.metric_key = d.metric_key

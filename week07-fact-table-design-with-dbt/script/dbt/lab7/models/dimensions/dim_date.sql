with bounds as (
    select
        min(order_date) as min_date,
        max(
            greatest(
                order_date,
                coalesce(shipped_date, order_date),
                coalesce(delivered_date, order_date)
            )
        ) as max_date
    from {{ ref('stg_orders_log') }}

),

date_spine as (
    select g.date_day::date as full_date
    from bounds
    cross join lateral generate_series(
        bounds.min_date,
        bounds.max_date,
        interval '1 day'
    ) as g(date_day)

)

select
    to_char(full_date, 'YYYYMMDD')::integer as date_key,
    full_date,
    extract(year from full_date)::integer as year,
    extract(month from full_date)::integer as month,
    extract(day from full_date)::integer as day,
    (
        extract(year from full_date)::integer * 100
        + extract(month from full_date)::integer
    ) as yyyymm
from date_spine

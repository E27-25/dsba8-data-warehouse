select
    to_char(d::date, 'YYYYMMDD')::integer as date_key,
    d::date as sale_date,
    extract(year from d)::integer as year,
    extract(quarter from d)::integer as quarter,
    extract(month from d)::integer as month,
    to_char(d, 'YYYY-MM') as year_month,
    extract(day from d)::integer as day_of_month
from generate_series(
    date '2024-07-01',
    date '2025-03-31',
    interval '1 day'
) as g(d)

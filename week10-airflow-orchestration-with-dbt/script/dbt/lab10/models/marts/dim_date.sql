with dates as (
    select distinct sale_date
    from {{ ref('stg_coffee_sales') }}
)

select
    to_char(sale_date, 'YYYYMMDD')::integer as date_key,
    sale_date as full_date,
    extract(year from sale_date)::integer as year,
    extract(month from sale_date)::integer as month_number,
    to_char(sale_date, 'Mon') as month_name,
    extract(day from sale_date)::integer as day_of_month
from dates

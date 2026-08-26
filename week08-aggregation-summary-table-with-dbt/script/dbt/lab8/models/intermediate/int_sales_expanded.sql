with months as (
    select month_start::date
    from generate_series(
        date '2024-07-01',
        date '2025-03-01',
        interval '1 month'
    ) as g(month_start)
),

expanded as (
    select
        s.*,
        m.month_start,
        map.target_store_code,
        make_date(
            extract(year from m.month_start)::integer,
            extract(month from m.month_start)::integer,
            least(
                extract(day from s.sale_date)::integer,
                extract(day from (
                    date_trunc('month', m.month_start)
                    + interval '1 month - 1 day'
                ))::integer
            )
        ) as target_sale_date
    from {{ ref('stg_coffee_sales') }} s
    cross join months m
    join {{ ref('int_invoice_store_map') }} map
      on s.invoice_number = map.invoice_number
)

select
    md5(sale_id::text || '|' || month_start::text) as sale_key,
    sale_id as source_sale_id,
    case
        when month_start = date '2024-07-01' then invoice_number
        else invoice_number || '_' || to_char(month_start, 'YYYYMM')
    end as invoice_number,
    target_sale_date as sale_date,
    customer_code,
    product_code,
    size,
    target_store_code as store_code,
    staff_code,
    promo_code,
    quantity,
    revenue,
    points_redeemed
from expanded

select
    snapshot_date_key,
    store_key,
    product_key,
    count(*) as row_count

from {{ ref('fact_orders_daily_snapshot') }}
group by snapshot_date_key, store_key, product_key
having count(*) > 1

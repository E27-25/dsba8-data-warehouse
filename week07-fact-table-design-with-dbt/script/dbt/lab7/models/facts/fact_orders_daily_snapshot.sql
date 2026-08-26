with snapshot_grid as (
    select
        d.date_key as snapshot_date_key,
        s.store_key,
        p.product_key
    from {{ ref('dim_date') }} as d
    cross join {{ ref('dim_store') }} as s
    cross join {{ ref('dim_product') }} as p

),

daily_activity as (
    select
        order_date_key as snapshot_date_key,
        store_key,
        product_key,
        count(distinct order_id)::integer as orders_count,
        sum(quantity)::integer as qty_sold,
        sum(gross_amount)::numeric(14, 2) as gross_amount,
        sum(discount_amount)::numeric(14, 2) as discount_amount,
        sum(net_amount)::numeric(14, 2) as net_amount,
        sum(margin_amount)::numeric(14, 2) as margin_amount
    from {{ ref('fact_orders_txn') }}
    group by order_date_key, store_key, product_key

)

select
    g.snapshot_date_key,
    g.store_key,
    g.product_key,
    coalesce(a.orders_count, 0) as orders_count,
    coalesce(a.qty_sold, 0) as qty_sold,
    coalesce(a.gross_amount, 0)::numeric(14, 2) as gross_amount,
    coalesce(a.discount_amount, 0)::numeric(14, 2)
        as discount_amount,
    coalesce(a.net_amount, 0)::numeric(14, 2) as net_amount,
    coalesce(a.margin_amount, 0)::numeric(14, 2) as margin_amount,
    cast('{{ run_started_at }}' as timestamptz) as load_datetime,
    '{{ invocation_id }}' as batch_id

from snapshot_grid as g
left join daily_activity as a
    on g.snapshot_date_key = a.snapshot_date_key
    and g.store_key = a.store_key
    and g.product_key = a.product_key

with stores as (
    select distinct
        store_code,
        store_name,
        province
    from {{ ref('stg_coffee_sales') }}
)

select
    md5(store_code) as store_key,
    store_code,
    store_name,
    province
from stores

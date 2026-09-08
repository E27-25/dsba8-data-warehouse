with products as (
    select distinct
        product_code,
        product_name,
        category,
        size,
        unit_price
    from {{ ref('stg_coffee_sales') }}
)

select
    md5(product_code) as product_key,
    product_code,
    product_name,
    category,
    size,
    unit_price
from products

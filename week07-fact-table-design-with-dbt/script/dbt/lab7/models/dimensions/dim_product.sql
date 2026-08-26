select
    md5(product_code) as product_key,
    product_code,
    max(product_name) as product_name,
    max(category) as category,
    case
        when bool_or(size in ('S', 'M', 'L')) then 'S/M/L'
        else '-'
    end as size_domain

from {{ ref('stg_orders_log') }}
group by product_code

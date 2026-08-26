select distinct
    md5(customer_code) as customer_key,
    customer_code,
    customer_name,
    gender,
    birth_year
from {{ ref('stg_coffee_sales') }}

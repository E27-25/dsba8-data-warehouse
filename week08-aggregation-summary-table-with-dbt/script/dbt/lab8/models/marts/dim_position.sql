select distinct
    md5(position) as position_key,
    position as position_name
from {{ ref('stg_coffee_sales') }}

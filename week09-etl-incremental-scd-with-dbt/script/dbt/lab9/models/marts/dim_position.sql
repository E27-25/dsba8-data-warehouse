{{ config(materialized='table') }}
select distinct md5(position) as position_key, position
from {{ ref('stg_coffee_sales') }}

{{ config(materialized='table') }}
select distinct md5(category) as category_key, category as category_name
from {{ ref('stg_coffee_sales') }}

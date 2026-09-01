{{ config(materialized='table') }}
select distinct
  md5(region_name) as region_key,
  region_name
from {{ ref('stg_province_region') }}

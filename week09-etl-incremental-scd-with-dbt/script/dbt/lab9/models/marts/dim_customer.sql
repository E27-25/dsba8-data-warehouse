{{ config(materialized='table') }}

with versioned as (
  select
    customer_code, customer_name, gender, birth_year,
    source_change_date::date as start_date,
    lead(source_change_date::date) over (
      partition by customer_code
      order by source_change_date::date
    ) as next_start_date,
    dbt_valid_to
  from {{ ref('snap_customer_scd') }}
)
select
  md5(concat_ws('|',customer_code,start_date::text)) as customer_key,
  customer_code, customer_name, gender, birth_year, start_date,
  coalesce(next_start_date - 1,date '9999-12-31') as end_date,
  (dbt_valid_to is null) as is_current
from versioned

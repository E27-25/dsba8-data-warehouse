with batch as (
  select *
  from {{ ref('stg_coffee_sales') }}
  {% if var('load_batch','initial') == 'initial' %}
  where sale_date < date '2031-04-15'
  {% else %}
  where sale_date >= date '2031-04-15'
  {% endif %}
), ranked as (
  select
    customer_code, customer_name, gender, birth_year,
    sale_date as source_change_date,
    row_number() over (
      partition by customer_code, customer_name
      order by sale_date, sale_id
    ) as rn
  from batch
)
select customer_code, customer_name, gender, birth_year, source_change_date
from ranked
where rn=1

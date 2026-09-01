select *
from {{ ref('stg_coffee_sales') }}
{% if var('load_batch','initial') == 'initial' %}
where sale_date < date '2031-04-15'
{% else %}
where sale_date >= date '2031-04-15'
{% endif %}

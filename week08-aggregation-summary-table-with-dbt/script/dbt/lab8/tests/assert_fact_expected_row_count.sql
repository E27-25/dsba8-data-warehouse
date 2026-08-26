select count(*) as actual_rows
from {{ ref('fct_sales') }}
having count(*) <> 27000

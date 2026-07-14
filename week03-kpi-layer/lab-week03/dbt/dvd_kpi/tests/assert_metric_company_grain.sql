select
 metric_month,
 metric_key,
 count(*) as row_count
from {{ ref('metric_company_monthly') }}
group by metric_month, metric_key
having count(*) > 1

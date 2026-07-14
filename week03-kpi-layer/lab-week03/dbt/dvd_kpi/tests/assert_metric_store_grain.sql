select
 metric_month,
 store_id,
 metric_key,
 count(*) as row_count
from {{ ref('metric_store_monthly') }}
group by metric_month, store_id, metric_key
having count(*) > 1

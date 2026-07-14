select
 'company'::varchar as source_model,
 metric_month,
 null::integer as store_id,
 metric_value
from {{ ref('metric_company_monthly') }}
where metric_key = 'M005'
 and (metric_value < 0 or metric_value > 1)
union all
select
 'store'::varchar as source_model,
 metric_month,
 store_id,
 metric_value
from {{ ref('metric_store_monthly') }}
where metric_key = 'M005'
 and (metric_value < 0 or metric_value > 1)

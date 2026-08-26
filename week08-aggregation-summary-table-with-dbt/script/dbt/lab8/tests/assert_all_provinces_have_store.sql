select p.*
from {{ ref('dim_province') }} p
left join {{ ref('dim_store') }} s
  on p.province_key = s.province_key
where s.store_key is null

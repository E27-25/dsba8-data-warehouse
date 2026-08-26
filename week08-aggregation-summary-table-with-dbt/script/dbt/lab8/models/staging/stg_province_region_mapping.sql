select
    trim(province_name) as province_name,
    trim(region_name) as region_name
from {{ ref('province_region_mapping_v2') }}

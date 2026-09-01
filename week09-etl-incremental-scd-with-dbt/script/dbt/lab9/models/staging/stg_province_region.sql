select province_name, region_name
from {{ ref('province_region_mapping_v2') }}

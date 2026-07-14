select
    inventory_id::integer as inventory_id,
    film_id::integer as film_id,
    store_id::integer as store_id
from {{ source('dvdrental', 'inventory') }}

with rental as (
    select * from {{ ref('stg_rental') }}
),
inventory as (
    select * from {{ ref('stg_inventory') }}
),
film as (
    select * from {{ ref('stg_film') }}
),
payment_by_rental as (
    select * from {{ ref('int_payment_by_rental') }}
)
select
    r.rental_id,
    r.rental_date,
    date_trunc('month', r.rental_date)::date as rental_month,
    r.return_date,
    r.customer_id,
    r.staff_id,
    i.store_id,
    i.film_id,
    f.film_title,
    f.rating,
    f.rental_duration,
    r.rental_date
        + (f.rental_duration * interval '1 day')
        as expected_return_datetime,
    coalesce(p.revenue_amount, 0)::numeric(12, 2)
        as revenue_amount,
    coalesce(p.payment_record_count, 0)::integer
        as payment_record_count,
    1::integer as rental_count,
    case
        when r.return_date is not null then 1
        else 0
    end::integer as returned_rental_count,
    case
        when r.return_date is not null
         and r.return_date >
             r.rental_date
             + (f.rental_duration * interval '1 day')
        then 1
        else 0
    end::integer as late_rental_count
from rental r
join inventory i
  on r.inventory_id = i.inventory_id
join film f
  on i.film_id = f.film_id
left join payment_by_rental p
  on r.rental_id = p.rental_id

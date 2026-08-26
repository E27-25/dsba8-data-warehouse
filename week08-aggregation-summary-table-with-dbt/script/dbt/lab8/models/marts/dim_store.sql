with existing_stores as (
    select distinct
        s.store_code,
        s.store_name,
        p.province_key,
        p.province_name
    from {{ ref('stg_coffee_sales') }} s
    join {{ ref('dim_province') }} p
      on s.province = p.province_name
),

provinces_without_store as (
    select
        p.province_key,
        p.province_name,
        row_number() over (order by p.province_name) as generated_num
    from {{ ref('dim_province') }} p
    left join existing_stores e
      on p.province_key = e.province_key
    where e.province_key is null
),

all_stores as (
    select
        md5(store_code) as store_key,
        store_code,
        store_name,
        province_key,
        false as is_generated
    from existing_stores

    union all

    select
        md5('GENERATED|' || province_name) as store_key,
        'ST' || lpad((generated_num + 3)::text, 3, '0') as store_code,
        province_name || ' Center' as store_name,
        province_key,
        true as is_generated
    from provinces_without_store
)

select * from all_stores

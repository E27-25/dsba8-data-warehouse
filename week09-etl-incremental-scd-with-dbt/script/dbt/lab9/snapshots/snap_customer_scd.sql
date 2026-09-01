{% snapshot snap_customer_scd %}
{{
  config(
    unique_key='customer_code',
    strategy='check',
    check_cols=['customer_name','gender','birth_year'],
    invalidate_hard_deletes=False
  )
}}
select * from {{ ref('int_customer_source') }}
{% endsnapshot %}

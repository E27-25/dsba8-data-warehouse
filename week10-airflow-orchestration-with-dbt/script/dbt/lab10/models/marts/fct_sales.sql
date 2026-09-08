select
    md5(s.sale_id::text) as sales_key,
    s.invoice_number,
    d.date_key,
    p.product_key,
    st.store_key,
    c.customer_key,
    pr.promotion_key,
    s.quantity,
    s.unit_price,
    s.revenue,
    s.points_redeemed
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_date') }} d
    on s.sale_date = d.full_date
join {{ ref('dim_product') }} p
    on s.product_code = p.product_code
join {{ ref('dim_store') }} st
    on s.store_code = st.store_code
join {{ ref('dim_customer') }} c
    on s.customer_code = c.customer_code
left join {{ ref('dim_promotion') }} pr
    on s.promo_code = pr.promo_code

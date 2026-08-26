select
    x.sale_key,
    x.source_sale_id,
    x.invoice_number,
    d.date_key,
    c.customer_key,
    p.product_key,
    st.store_key,
    sf.staff_key,
    pr.promo_key,
    x.quantity,
    x.revenue,
    x.points_redeemed
from {{ ref('int_sales_expanded') }} x
join {{ ref('dim_date') }} d
  on x.sale_date = d.sale_date
join {{ ref('dim_customer') }} c
  on x.customer_code = c.customer_code
join {{ ref('dim_product') }} p
  on x.product_code = p.product_code
 and x.size = p.size
join {{ ref('dim_store') }} st
  on x.store_code = st.store_code
join {{ ref('dim_staff') }} sf
  on x.staff_code = sf.staff_code
left join {{ ref('dim_promotion') }} pr
  on x.promo_code = pr.promo_code

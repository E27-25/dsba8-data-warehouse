# 📦 Week 3: Requirement Gathering & KPI Layer

> **Course:** Data Warehousing (การสร้างคลังข้อมูล)  
> **Topic:** Requirement Gathering, Business Process, KPI Layer with dbt & Metabase  
> **Duration:** 2 Hours

---

## 🎯 Learning Objectives / วัตถุประสงค์

1. วิเคราะห์ Subject Area, Business Process และคำถามทางธุรกิจจากกรณีศึกษา dvdrental ได้
2. กำหนด KPI, สูตรคำนวณ, หน่วยวัด และ Granularity ที่ชัดเจนได้
3. อธิบายปัญหาการนับซ้ำที่เกิดจากการ Join ตาราง payment กับ rental ได้
4. สร้าง dbt project และพัฒนา Staging, Intermediate, Fact และ Metric Models ได้
5. สร้าง Metric Key Catalog ด้วย dbt seed เพื่อให้ KPI มีรหัสและนิยามมาตรฐาน
6. ตรวจสอบความถูกต้องของข้อมูลด้วย dbt tests และนำ Metric Models ไปสร้าง Dashboard บน Metabase ได้

---

## 🧰 Tools & Stack Overview / เครื่องมือที่ใช้

| Tool | What is it used for in this lab? |
|---|---|
| **Docker Compose** | รัน PostgreSQL, pgAdmin, dbt, Metabase และบริการอื่นใน environment เดียวกัน |
| **PostgreSQL** | เก็บฐานข้อมูลต้นทาง dvdrental และผลลัพธ์ที่ dbt สร้าง |
| **dbt Core** | จัดการ SQL transformation, dependency, seed, test และสร้าง KPI Layer |
| **pgAdmin** | ตรวจสอบฐานข้อมูล ตาราง View และผลลัพธ์ของ dbt |
| **Metabase** | สร้าง Dashboard จาก Metric Models โดยไม่เขียนสูตร KPI ซ้ำ |
| **VS Code / Text Editor** | สร้างและแก้ไขไฟล์ .sql, .yml และ .csv ใน dbt project |

---

## 📁 Files in This Week / ไฟล์ในสัปดาห์นี้

| File / Folder | Description |
|---|---|
| 📂 [slides/](./slides/) | Lecture slides |
| └── 📄 [3 - Requirement Gathering for DW.pdf](./slides/3%20-%20Requirement%20Gathering%20for%20DW.pdf) | Lecture: Requirement Gathering for DW |
| 📂 [docs/](./docs/) | Lab instructions |
| ├── 📄 [Lab3 KPI Layer.pdf](./docs/Lab3%20KPI%20Layer.pdf) | Lab instruction (PDF) |
| └── 📝 [Lab3 KPI Layer.docx](./docs/Lab3%20KPI%20Layer.docx) | Lab instruction (Word) |

---

## 🔧 ส่วนที่ 1: สร้างโครงสร้าง dbt Project

ในโฟลเดอร์ `week01-data-warehouse-setup/lab-week01` ให้สร้างโฟลเดอร์และไฟล์ตามโครงสร้างต่อไปนี้โดยใช้ File Explorer หรือ VS Code (โฟลเดอร์ dbt และ dbt_root จะถูก mount เข้าไปใน container ทันที):

```text
lab-week01/
├── docker-compose.yaml
├── dbt/
│   └── dvd_kpi
│       ├── dbt_project.yml
│       ├── models/
│       │   ├── sources.yml
│       │   ├── schema.yml
│       │   ├── staging/
│       │   │   ├── stg_rental.sql
│       │   │   ├── stg_payment.sql
│       │   │   ├── stg_inventory.sql
│       │   │   └── stg_film.sql
│       │   ├── intermediate/
│       │   │   └── int_payment_by_rental.sql
│       │   └── marts/
│       │       ├── fct_rental_activity.sql
│       │       ├── metric_company_monthly.sql
│       │       └── metric_store_monthly.sql
│       ├── seeds/
│       │   └── metric_definition.csv
│       └── tests/
│           ├── assert_metric_company_grain.sql
│           ├── assert_metric_store_grain.sql
│           └── assert_late_return_rate_range.sql
└── dbt_root/
    └── profiles.yml
```

---

## ⚙️ ส่วนที่ 2: ตั้งค่า dbt Project และ Connection

### 2.1 สร้างไฟล์ `dbt/dvd_kpi/dbt_project.yml`
```yaml
name: dvd_kpi
version: '1.0.0'
config-version: 2

profile: dvd_kpi

model-paths: ['models']
seed-paths: ['seeds']
test-paths: ['tests']

clean-targets:
  - 'target'
  - 'dbt_packages'

models:
  dvd_kpi:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: view
      +schema: metrics

seeds:
  dvd_kpi:
    +schema: metadata
    metric_definition:
      +column_types:
        metric_key: varchar(10)
```

### 2.2 สร้างไฟล์ `dbt_root/profiles.yml`
```yaml
dvd_kpi:
  target: dev
  outputs:
    dev:
      type: postgres
      host: postgres
      port: 5432
      user: dw_user
      password: dw_pass
      dbname: dvdrental
      schema: dbt
      threads: 4
```

### 2.3 ทดสอบ Connection
รันคำสั่งต่อไปนี้เพื่อเข้าไปใน container และทดสอบ:
```bash
docker exec -it dw_dbt bash
cd dvd_kpi
dbt debug
```
*(ควรแสดงข้อความ `All checks passed`)*

---

## 📥 ส่วนที่ 3: ประกาศ Source Tables

### 3.1 สร้างไฟล์ `dbt/dvd_kpi/models/sources.yml`
```yaml
version: 2

sources:
  - name: dvdrental
    database: dvdrental
    schema: public
    tables:
      - name: rental
      - name: payment
      - name: inventory
      - name: film
```

### 3.2 ตรวจสอบว่า dbt อ่าน Project ได้
```bash
docker exec -it dw_dbt bash -c "cd dvd_kpi && dbt parse"
```

---

## 🏗️ ส่วนที่ 4: สร้าง Staging Models

สร้างไฟล์ SQL ต่อไปนี้ในโฟลเดอร์ `models/staging/`:

**`stg_rental.sql`**
```sql
select
    rental_id::integer as rental_id,
    rental_date::timestamp as rental_date,
    inventory_id::integer as inventory_id,
    customer_id::integer as customer_id,
    return_date::timestamp as return_date,
    staff_id::integer as staff_id
from {{ source('dvdrental', 'rental') }}
```

**`stg_payment.sql`**
```sql
select
    payment_id::integer as payment_id,
    customer_id::integer as customer_id,
    staff_id::integer as staff_id,
    rental_id::integer as rental_id,
    amount::numeric(12, 2) as amount,
    payment_date::timestamp as payment_date
from {{ source('dvdrental', 'payment') }}
```

**`stg_inventory.sql`**
```sql
select
    inventory_id::integer as inventory_id,
    film_id::integer as film_id,
    store_id::integer as store_id
from {{ source('dvdrental', 'inventory') }}
```

**`stg_film.sql`**
```sql
select
    film_id::integer as film_id,
    title::varchar as film_title,
    rental_duration::integer as rental_duration,
    rating::varchar as rating
from {{ source('dvdrental', 'film') }}
```

**ทดสอบสร้าง Staging Views:**
```bash
docker exec -it dw_dbt bash -c "cd dvd_kpi && dbt run --select stg_rental stg_payment stg_inventory stg_film"
```

---

## 🔄 ส่วนที่ 5: Aggregate Payment ให้ตรงกับ Grain

### 5.2 สร้าง `models/intermediate/int_payment_by_rental.sql`
```sql
select
    rental_id,
    sum(amount)::numeric(12, 2) as revenue_amount,
    count(*)::integer as payment_record_count
from {{ ref('stg_payment') }}
where rental_id is not null
group by rental_id
```

---

## 🏭 ส่วนที่ 6: สร้าง Fact Model

### 6.1 สร้าง `models/marts/fct_rental_activity.sql`
```sql
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
```

---

## 📖 ส่วนที่ 7: สร้าง Metric Key Catalog ด้วย dbt Seed

### 7.1 สร้าง `seeds/metric_definition.csv`
```csv
metric_key,metric_name,metric_label,description,formula,unit
M001,total_revenue,Total Revenue,"รายได้รวมจาก payment ที่ aggregate ต่อ rental แล้ว",SUM(revenue_amount),currency
M002,rental_count,Rental Count,"จำนวนการเช่าภาพยนตร์",SUM(rental_count),count
M003,active_customer_count,Active Customer Count,"จำนวนลูกค้าที่มี rental แบบไม่ซ้ำ",COUNT_DISTINCT(customer_id),count
M004,average_revenue_per_rental,Average Revenue per Rental,"รายได้เฉลี่ยต่อการเช่าหนึ่งครั้ง",M001/M002,currency_per_rental
M005,late_return_rate,Late Return Rate,"สัดส่วนรายการคืนล่าช้าต่อรายการที่คืนแล้ว",late_rental_count/returned_rental_count,ratio
```

### 7.2 โหลด Seed เข้า PostgreSQL
```bash
docker exec -it dw_dbt bash -c "cd dvd_kpi && dbt seed --full-refresh"
```

---

## 🏢 ส่วนที่ 8: สร้าง Metric Model ระดับบริษัท

### 8.1 สร้าง `models/marts/metric_company_monthly.sql`
```sql
with monthly_base as (
    select
        rental_month as metric_month,
        sum(revenue_amount) as total_revenue,
        sum(rental_count) as rental_count,
        count(distinct customer_id) as active_customer_count,
        sum(late_rental_count) as late_rental_count,
        sum(returned_rental_count) as returned_rental_count
    from {{ ref('fct_rental_activity') }}
    group by rental_month
),
metric_values as (
    select
        metric_month,
        'M001'::varchar as metric_key,
        total_revenue::numeric(18, 4) as metric_value
    from monthly_base
    union all
    select
        metric_month,
        'M002',
        rental_count::numeric(18, 4)
    from monthly_base
    union all
    select
        metric_month,
        'M003',
        active_customer_count::numeric(18, 4)
    from monthly_base
    union all
    select
        metric_month,
        'M004',
        (
            total_revenue
            / nullif(rental_count, 0)
        )::numeric(18, 4)
    from monthly_base
    union all
    select
        metric_month,
        'M005',
        (
            late_rental_count::numeric
            / nullif(returned_rental_count, 0)
        )::numeric(18, 4)
    from monthly_base
)
select
    v.metric_month,
    v.metric_key,
    d.metric_name,
    d.metric_label,
    d.description,
    d.formula,
    d.unit,
    v.metric_value
from metric_values v
join {{ ref('metric_definition') }} d
  on v.metric_key = d.metric_key
```

---

## 🏪 ส่วนที่ 9: สร้าง Metric Model ระดับสาขา

### 9.1 สร้าง `models/marts/metric_store_monthly.sql`
*(คล้ายกับ `metric_company_monthly.sql` แต่เพิ่ม `store_id` ลงใน `group by` ของ `monthly_base` และเลือก `store_id` ในทุก ๆ union query)*

*(See detailed SQL in Lab PDF page 11)*

---

## 🧪 ส่วนที่ 10: กำหนด Documentation และ Data Tests

สร้างไฟล์ `models/schema.yml` เพื่อตั้งค่า tests ต่างๆ เช่น `not_null`, `unique` และ `relationships` รวมถึงสร้าง Data Tests ในโฟลเดอร์ `tests/`:

- `tests/assert_metric_company_grain.sql`
- `tests/assert_metric_store_grain.sql`
- `tests/assert_late_return_rate_range.sql`

---

## 🚀 ส่วนที่ 11: Build และตรวจสอบผลลัพธ์

### 11.1 สร้างทุก Model และรัน Test
```bash
docker exec -it dw_dbt bash -c "cd dvd_kpi && dbt build"
```

### 11.2 - 11.5 ตรวจสอบข้อมูลใน pgAdmin หรือ Metabase (SQL Editor)
```sql
-- ตรวจสอบ Metric Catalog
SELECT * FROM dbt_metadata.metric_definition ORDER BY metric_key;

-- ตรวจสอบ KPI ระดับบริษัท
SELECT * FROM dbt_metrics.metric_company_monthly LIMIT 20;

-- ตรวจสอบ KPI ระดับสาขา
SELECT * FROM dbt_metrics.metric_store_monthly LIMIT 30;
```

---

## 📊 ส่วนที่ 12: นำ Metric Key ไปใช้ใน Metabase

1. เปิด Metabase `http://localhost:23000` และ **Sync Schema** ให้เห็น `dbt_metrics`
2. สร้าง Question: **KPI Trend by Metric Key** (Line Chart, Filter `M001`)
3. สร้าง Question: **KPI by Store** (Bar Chart, Filter `M001`)
4. สร้าง Question: **Late Return Rate by Store** (Bar Chart, Filter `M005`, Format เป็น Percent)
5. สร้าง Question: **Metric Catalog** (Table)
6. นำมารวมกันใน **DVD Rental KPI Dashboard - [รหัสนักศึกษา]** พร้อมเพิ่ม Filter `Metric Key` และ `Date`

---

## 📝 ส่วนที่ 13: คำถามวิเคราะห์ / สิ่งที่ต้องส่ง

**1. Submission:** ส่ง Screenshot หน้า Metabase Dashboard เป็นไฟล์ PNG/JPG

**2. Analysis Questions:** ตอบคำถาม 4 ข้อลงใน Google Form:
1. เพราะเหตุใดจึงต้อง Aggregate payment ให้เหลือหนึ่งแถวต่อ rental_id ก่อน Join กับ rental?
2. เพราะเหตุใด Active Customer Count รายปีจึงไม่ควรคำนวณด้วยการบวก Active Customer Count ของแต่ละเดือน?
3. ถ้าเปลี่ยนนิยาม Late Return เป็น “คืนเกินกำหนดอย่างน้อย 2 วัน” ต้องแก้ไขไฟล์ใด และต้องรันคำสั่งใดอีกครั้ง?
4. หากให้ผู้ใช้เขียนสูตร M004 และ M005 เองทุก Dashboard จะเกิดความเสี่ยงอย่างไร?

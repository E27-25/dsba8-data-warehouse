# 📦 Week 8: Granularity, Aggregation & Summary Table

> **Course:** Data Warehousing (การสร้างคลังข้อมูล)  
> **Topic:** OLAP — Roll-up, Drill-down และ CUBE ด้วย dbt  
> **Duration:** 2 Hours

> 💡 **Lab concept / แนวคิดหลัก:** ขยายข้อมูลขายเดือนเดียวให้ครบ **9 เดือน × 77 จังหวัด**
> แล้วสร้าง **Aggregate Table** ที่ grain = **หนึ่งเดือนต่อหนึ่ง region** พร้อม **Roll-up**,
> **Drill-down** และ **CUBE** models ก่อนนำขึ้น Dashboard บน Metabase

> 📷 The screenshot blocks below point at `docs/screenshots/`. Capture each output as you run the
> lab and drop the PNGs there — filenames already match.

---

## 🎯 Learning Objectives / วัตถุประสงค์

1. อธิบาย **grain** ของ fact table และเปรียบเทียบข้อมูลระดับ **transaction, รายวัน และรายเดือน** ได้
2. จำแนก measures เป็น **Additive**, **Semi-additive** และ **Non-additive** ได้อย่างเหมาะสม
3. ใช้ `dbt seed` และ dbt models เตรียมข้อมูลหลายเดือนและร้านค้าในทุกจังหวัดได้
4. สร้าง **aggregate table** ที่มี grain เป็นหนึ่งแถวต่อเดือนต่อ region ด้วย `ref()` ได้
5. ใช้ `dbt test` ตรวจ **grain, row count, referential integrity** และการ **กระทบยอด** กับ fact table ได้
6. สร้าง **Roll-up**, **Drill-down** และ **CUBE** models แล้วนำไปวิเคราะห์บน Metabase ได้

---

## 🧰 Tools & Stack Overview / เครื่องมือที่ใช้

| Tool                            | What is it?                  | หน้าที่ใน Lab                                                       |
| ------------------------------- | ---------------------------- | ------------------------------------------------------------------------- |
| **PostgreSQL 16**         | Relational Database (RDBMS)  | จัดเก็บ seed, models, aggregate table และ reporting views |
| **dbt-postgres**          | Transformation Framework     | `seed`, transform, `test`, document และแสดง lineage           |
| **Metabase**              | BI / Dashboard Tool          | สร้างกราฟและ Dashboard สำหรับ Roll-up / Drill-down     |
| **Docker Compose**        | Containerization             | เปิด services `postgres`, `dbt` และ `metabase`              |
| **VS Code / Text Editor** | Editor                       | สร้างไฟล์ SQL และ YAML ในโครงการ dbt                     |

**Dataset / ชุดข้อมูล**

| Dataset                             |  Rows | รายละเอียด                                                      |
| ----------------------------------- | ----: | ------------------------------------------------------------------------ |
| `coffee_sales.csv`                | 3,000 | รายการขาย `2024-07-01` → `2024-07-31` (ชุดเดียวกับ Lab 4–5) |
| `province_region_mapping_v2.csv`  |    77 | 77 จังหวัด แบ่งเป็น **6 regions**                       |

> 📝 **ร้านค้าในข้อมูลจริงมีเพียง 3 แห่ง** — `ST01` Siam Center (Bangkok), `ST02` Nimman CM
> (Chiang Mai) และ `ST03` Central Korat (Nakhon Ratchasima) — Lab นี้จะสร้างร้านจำลองเพิ่ม
> ให้ครบทุกจังหวัดใน Part 4.3

---

## 📁 Files in This Week / ไฟล์ในสัปดาห์นี้

| File / Folder                                                                                                                        | Description                                              |
| ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| 📂[docs/](./docs/)                                                                                                                    | Lab instructions                                         |
| ├── 📝[Lab8 Aggregation _ Summary Table with dbt.docx](<./docs/Lab8%20Aggregation%20_%20Summary%20Table%20with%20dbt.docx>)        | Lab instruction (Word)                                   |
| ├── 📄[Lab8 Aggregation _ Summary Table with dbt.pdf](<./docs/Lab8%20Aggregation%20_%20Summary%20Table%20with%20dbt.pdf>)          | Lab instruction (PDF)                                    |
| └── 📂[screenshots/](./docs/screenshots/)                                                                                          | Images referenced by this README                         |
| 📂[script/](./script/)                                                                                                                | **ไฟล์ `.sql` / `.yml` ทั้งหมดของ Lab เตรียมไว้ให้** — ใช้กับ "คำสั่งลัด" ในแต่ละหัวข้อ |
| 📂[lab-week08/](./lab-week08/)                                                                                                        | **Lab working directory**                          |
| ├── 📂[dbt_root/](./lab-week08/dbt_root/)                                                                                          | Holds`profiles.yml` — the dbt connection profile      |
| │&nbsp;&nbsp;&nbsp;└── ⚙️ [profiles.yml](./lab-week08/dbt_root/profiles.yml)                                                       | Connects dbt to PostgreSQL, database`lab8`             |
| └── 📂[dbt/lab8/](./lab-week08/dbt/lab8/)                                                                                          | dbt project — models & tests are created during the lab |
| &nbsp;&nbsp;&nbsp;&nbsp;├── ⚙️ [dbt_project.yml](./lab-week08/dbt/lab8/dbt_project.yml)                                            | Materializations + schemas per folder                    |
| &nbsp;&nbsp;&nbsp;&nbsp;└── 📂 [seeds/](./lab-week08/dbt/lab8/seeds/)                                                              | Seed CSVs, already in place                              |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── 📊 [coffee_sales.csv](./lab-week08/dbt/lab8/seeds/coffee_sales.csv)            | 3,000 line items, July 2024                              |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── 📊 [province_region_mapping_v2.csv](./lab-week08/dbt/lab8/seeds/province_region_mapping_v2.csv) | 77 provinces → 6 regions                             |

---

## 🔧 Part 0: Start the Environment & Connect Tools / เริ่มระบบและเชื่อมต่อเครื่องมือ

> 💡 **Note:** If your Docker stack from Week 1 is already running, confirm with `docker compose ps` and skip to Part 1.

### 0.1 Start Docker Containers / สตาร์ทระบบด้วย Docker

Reuse the Week 1 stack (it contains `dw_postgres`, `dw_dbt`, `pgAdmin`, and `Metabase`):

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
echo -e "AIRFLOW_UID=$(id -u)" > .env
docker compose up -d
docker compose ps
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup/lab-week01
Set-Content -Path .env -Value "AIRFLOW_UID=50000"
docker compose up -d
docker compose ps
```

> 💡 Tip: paste as a single line if the line breaks cause errors.

---

### 0.2 Connect pgAdmin to PostgreSQL / เชื่อมต่อ pgAdmin กับ PostgreSQL

1. Open your browser and go to **pgAdmin**: [http://localhost:28880](http://localhost:28880)
2. Log in with the default credentials:
   - **Email:** `dw_user@mail.com`
   - **Password:** `dw_pass`
3. Register the PostgreSQL Server (if not already connected):
   - Right-click **Servers** ➡️ **Register** ➡️ **Server...**
   - Under the **General** tab:
     - **Name:** `DW Postgres`
   - Under the **Connection** tab:
     - **Host name/address:** `dw_postgres` *(Internal Docker container name)*
     - **Port:** `5432`
     - **Maintenance database:** `airflow`
     - **Username:** `dw_user`
     - **Password:** `dw_pass`
   - Click **Save**.

---

## 🧩 Part 1: Analyze Granularity & Additivity / วิเคราะห์ Granularity และ Additivity

### 1.1 ระบุ grain ก่อนเขียน SQL

**Grain** คือคำอธิบายว่า **1 แถว** ของตารางแทนเหตุการณ์หรือสรุปข้อมูลในระดับใด
ต้องกำหนด grain **ก่อน** เลือก dimension keys และ measures

| Model / Query                | Grain: หนึ่งแถวแทน...                                       | คีย์ที่กำหนด grain              |
| ---------------------------- | ------------------------------------------------------------------- | ---------------------------------------- |
| `fct_sales`                | หนึ่งรายการสินค้าในใบเสร็จ หลังขยายเป็นเดือนเป้าหมาย | `sale_key`                             |
| `rpt_sales_store_day`      | หนึ่งวันต่อหนึ่งร้าน                                  | `sale_date` + `store_key`            |
| `agg_sales_region_month`   | หนึ่งเดือนต่อหนึ่ง region                              | `month_start` + `region_key`         |
| `rpt_sales_region_quarter` | หนึ่งไตรมาสต่อหนึ่ง region                            | `quarter_start` + `region_key`       |

> ✅ **หลักตรวจ grain:** หาก `GROUP BY` ใช้ `month_start` และ `region_key` ผลลัพธ์ต้องมีได้
> **ไม่เกินหนึ่งแถวต่อคู่ค่านี้** — `dbt test` ใน Part 6 จะตรวจเงื่อนไขดังกล่าวอีกครั้ง

### 1.2 จำแนก Measures ตาม Additivity *(worksheet)*

เติมคอลัมน์ขวาก่อนเขียน SQL — ใช้ประกอบการอธิบายใน Part 5 และ Part 7:

| Measure                                              | เกิดใน                          | Additivity |
| ---------------------------------------------------- | ----------------------------------- | :--------: |
| `revenue` / `total_revenue`                      | `fct_sales` / aggregate           | ?          |
| `quantity` / `total_quantity`                    | `fct_sales` / aggregate           | ?          |
| `points_redeemed` / `total_points_redeemed`      | `fct_sales` / aggregate           | ?          |
| `invoice_count` (`count(distinct invoice_number)`) | reporting / aggregate               | ?          |
| `line_item_count` (`count(*)`)                     | aggregate                           | ?          |
| `unit_price`                                       | `dim_product`                     | ?          |
| ยอดเฉลี่ยต่อใบเสร็จ / % ส่วนแบ่ง | คำนวณตอน Query               | ?          |

> 💡 **คำใบ้:** measure ที่ **SUM ต่อได้ทุกมิติ** คือ **Additive**, ที่ **รวมข้ามเวลาไม่ได้**
> คือ **Semi-additive**, และค่าที่ต้อง **คำนวณใหม่จาก numerator และ denominator** คือ **Non-additive**
> — `count(distinct ...)` ก็รวมข้ามกลุ่มไม่ได้เช่นกัน

---

## 📥 Part 2: Prepare the Lab Environment / เตรียม Lab Environment

### 2.1 เปิด services และสร้างฐานข้อมูล

ใน pgAdmin ➡️ Query Tool (หรือ psql) รันคำสั่ง:

```sql
CREATE DATABASE lab8;
```

<details>
<summary><b>📷 pgAdmin — create database <code>lab8</code></b></summary>

![Create database lab8 in pgAdmin](./docs/screenshots/pgadmin-create-database.png)

</details>

> 💡 **ทางเลือกจาก Terminal** (เหมือนกันทุก OS):

```bash
docker exec -it dw_postgres psql -U dw_user -d airflow -c "CREATE DATABASE lab8;"
```

---

### 2.2 สร้างโครงสร้างโครงการ dbt

สร้างไฟล์และโฟลเดอร์ต่อไปนี้ **ในโฟลเดอร์เดียวกับ `docker-compose.yaml`**:

```text
lab-week01/                              ← root: โฟลเดอร์ที่มี docker-compose.yaml
│                                          (ถ้าเริ่มจาก 0 โดยแตกไฟล์ DWH_Lab.zip → root ชื่อ DWH_Lab/)
├── docker-compose.yaml                  ← มีอยู่แล้วจาก Week 1
├── dbt_root/
│   └── profiles.yml
└── dbt/
    └── lab8/
        ├── dbt_project.yml
        ├── seeds/
        │   ├── coffee_sales.csv
        │   └── province_region_mapping_v2.csv
        ├── models/
        │   ├── staging/
        │   │   ├── stg_coffee_sales.sql
        │   │   └── stg_province_region_mapping.sql
        │   ├── intermediate/
        │   │   ├── int_invoice_store_map.sql
        │   │   └── int_sales_expanded.sql
        │   ├── marts/
        │   │   ├── dim_customer.sql
        │   │   ├── dim_category.sql
        │   │   ├── dim_product.sql
        │   │   ├── dim_position.sql
        │   │   ├── dim_staff.sql
        │   │   ├── dim_promotion.sql
        │   │   ├── dim_region.sql
        │   │   ├── dim_province.sql
        │   │   ├── dim_store.sql
        │   │   ├── dim_date.sql
        │   │   └── fct_sales.sql
        │   ├── aggregates/
        │   │   └── agg_sales_region_month.sql
        │   ├── reporting/
        │   │   ├── rpt_sales_store_day.sql
        │   │   ├── rpt_sales_region_quarter.sql
        │   │   ├── rpt_sales_province_quarter.sql
        │   │   └── rpt_sales_staff_year_cube.sql
        │   └── schema.yml
        └── tests/
            ├── assert_all_provinces_have_store.sql
            ├── assert_fact_expected_row_count.sql
            ├── assert_summary_grain.sql
            └── assert_summary_reconciles.sql
```

> 📝 **ใบ Lab เขียนผังย่อว่า `marts/dim_*.sql`** — ผังด้านบนแจกแจงครบทั้ง **10 dimension models
> + 1 fact model** ตามที่ Part 4 สร้างจริง

> ⚠️ **root อยู่ที่ไหน — ใบ Lab เรียกว่า `DWH_Lab` แต่ในรีโปนี้ชื่อ `lab-week01`**
> `docker-compose.yaml` mount แบบ **relative กับตำแหน่งของตัวมันเอง** (`./dbt:/usr/app` และ
> `./dbt_root:/root/.dbt`) ดังนั้น `dbt/` และ `dbt_root/` ต้องอยู่ **ข้าง ๆ** `docker-compose.yaml`
> เสมอ ไม่ว่าโฟลเดอร์นั้นจะชื่ออะไร
>
> | สถานะของคุณ | root คือ |
> |---|---|
> | ทำต่อจาก Week 1 มาเรื่อย ๆ | `dsba8-data-warehouse/week01-data-warehouse-setup/lab-week01/` |
> | เริ่มจาก 0 (คอมโดนล้าง / เครื่องใหม่) | `DWH_Lab/` — ได้จากการแตกไฟล์ [`DWH_Lab.zip`](../week01-data-warehouse-setup/lab-week01/DWH_Lab.zip) |
>
> ทั้งสองแบบใช้คำสั่งเดียวกันทุกบรรทัดหลังจาก `cd` เข้า root แล้ว

> 💡 **เช็กว่ายืนถูกที่หรือยัง** — สั่งแล้วต้องเห็น `docker-compose.yaml`
>
> **Mac / Linux:** `ls docker-compose.yaml` · **Windows (PowerShell):** `Test-Path docker-compose.yaml`

Create the folders (only the shell syntax differs):

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01     # เริ่มจาก 0: cd DWH_Lab
mkdir -p dbt_root dbt/lab8/seeds \
  dbt/lab8/models/staging dbt/lab8/models/intermediate dbt/lab8/models/marts \
  dbt/lab8/models/aggregates dbt/lab8/models/reporting \
  dbt/lab8/tests
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01     # เริ่มจาก 0: cd DWH_Lab
New-Item -ItemType Directory -Force dbt_root, dbt/lab8/seeds, `
  dbt/lab8/models/staging, dbt/lab8/models/intermediate, dbt/lab8/models/marts, `
  dbt/lab8/models/aggregates, dbt/lab8/models/reporting, `
  dbt/lab8/tests
```

> 💡 Tip: paste as a single line if the line breaks cause errors. คำสั่ง `cd` ด้านบนนับจาก
> root ของรีโป — ถ้าอยู่ที่อื่นให้ใช้ path เต็มแทน

<details>
<summary><b>⚡ คำสั่งลัด — วางไฟล์ SQL/YAML ทั้งหมดของ Lab นี้ในครั้งเดียว</b></summary>

ทุกไฟล์ `.sql` และ `.yml` ของ Lab นี้เตรียมไว้แล้วใน [`script/`](./script/) ถ้าไม่อยากสร้างไฟล์
ทีละไฟล์แล้ว copy-paste จาก README ให้คัดลอกทั้งชุดทีเดียว **หลังจาก `cd` เข้า root แล้ว**:

**Mac / Linux:**

```bash
cp -r ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/. dbt/lab8/
```

**Windows (PowerShell):**

```powershell
Copy-Item -Recurse -Force ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\* dbt\lab8\
```

> ⚠️ คำสั่งนี้แตะเฉพาะ `dbt/lab8/` เท่านั้น — **ไม่รวม `dbt_root/profiles.yml`** ซึ่งใช้ร่วมกัน
> ทุก Lab และต้องเพิ่ม block เองตาม Part 2.3 ส่วน `seeds/*.csv` ที่คัดลอกไว้ก่อนหน้า
> จะไม่ถูกลบ เพราะเป็นการ merge ไม่ใช่ replace

> 📝 ถึงจะใช้คำสั่งลัด ก็ยัง**ควรอ่านคำอธิบายของแต่ละไฟล์ใน Part 3–5** เพราะข้อสอบและ
> Google Form ถามจากเหตุผลเบื้องหลัง ไม่ใช่แค่ผลลัพธ์ที่รันได้

</details>

> ⚠️ **`dbt_root/profiles.yml` เป็นไฟล์ที่ใช้ร่วมกันทุก Lab** — ถ้าคุณทำ Lab 3–7 มาแล้ว ไฟล์นี้
> มี profile ของสัปดาห์ก่อนอยู่ ให้ **เพิ่ม** block `lab8:` ต่อท้าย (Part 2.3) **ห้ามเขียนทับทั้งไฟล์**
> ไม่งั้น Lab เก่าจะรันไม่ได้

> 📝 **ตำแหน่งไฟล์ dataset:** คัดลอก `coffee_sales.csv` และ `province_region_mapping_v2.csv`
> ไปไว้ใน `dbt/lab8/seeds/` โดยคงชื่อไฟล์เดิม — ในรีโปนี้อยู่ที่
> [`lab-week08/dbt/lab8/seeds/`](./lab-week08/dbt/lab8/seeds/) ให้แล้ว
>
> **Mac / Linux:**
>
> ```bash
> cp ../../week08-aggregation-summary-table-with-dbt/lab-week08/dbt/lab8/seeds/*.csv dbt/lab8/seeds/
> ```
>
> **Windows (PowerShell):**
>
> ```powershell
> Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\lab-week08\dbt\lab8\seeds\*.csv dbt\lab8\seeds\
> ```

---

### 2.3 กำหนด profile และ project configuration

`dbt_root/profiles.yml`

> 📝 **นี่คือ block ที่ต้อง _เพิ่ม_ ไม่ใช่ทั้งไฟล์** — ถ้าเคยทำ Lab 3–7 ไฟล์นี้จะมี profile
> ของสัปดาห์ก่อน (`dvd_kpi`, `coffee_dw`, `coffee_dw_snowflake`, `coffee_dw_scd`, `lab7`)
> อยู่แล้ว ให้วาง `lab8:` ต่อท้ายโดยไม่ลบของเดิม (ถ้าเริ่มจาก 0 ไฟล์ยังว่าง — ใส่เฉพาะ block นี้ได้เลย)

```yaml
lab8:
  target: dev
  outputs:
    dev:
      type: postgres
      host: postgres
      port: 5432
      user: dw_user
      password: dw_pass
      dbname: lab8
      schema: dbt
      threads: 4
```

<details>
<summary><b>⚡ คำสั่งลัด — ไฟล์เตรียมไว้ให้แล้ว</b></summary>

ไฟล์ตัวอย่างอยู่ที่ [`script/dbt_root/profiles.yml`](./script/dbt_root/profiles.yml) — แต่ **ห้ามคัดลอกทับ** เพราะ
`profiles.yml` ใช้ร่วมกันทุก Lab ให้เปิดไฟล์นั้นแล้ว **คัดลอกเฉพาะ block ไปต่อท้าย**
ไฟล์จริงที่ `dbt_root/profiles.yml` ของคุณ

</details>

> ⚠️ **ชื่อ host:** dbt ทำงานใน Docker network จึงเชื่อม PostgreSQL ด้วยชื่อ service `postgres`
> และพอร์ตภายใน `5432` — **ไม่ใช้** `localhost` หรือพอร์ต `25432`

`dbt/lab8/dbt_project.yml`

```yaml
name: lab8
version: '1.0.0'
config-version: 2

profile: lab8

model-paths: ["models"]
seed-paths: ["seeds"]
test-paths: ["tests"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

models:
  lab8:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +materialized: table
      +schema: marts
    aggregates:
      +materialized: table
      +schema: aggregates
    reporting:
      +materialized: view
      +schema: reporting

seeds:
  lab8:
    +schema: raw
    coffee_sales:
      +column_types:
        sale_id: integer
        sale_date: date
        birth_year: integer
        unit_price: numeric(12,2)
        quantity: integer
        revenue: numeric(14,2)
        points_redeemed: integer
    province_region_mapping_v2:
      +column_types:
        province_name: varchar(100)
        region_name: varchar(50)
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/dbt_project.yml`](./script/dbt/lab8/dbt_project.yml)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/dbt_project.yml dbt/lab8/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\dbt_project.yml dbt\lab8\
```

</details>

> 📝 **ชื่อ schema จริงใน PostgreSQL:** dbt ต่อ `+schema` เข้ากับ `schema:` ใน `profiles.yml`
> เป็น `<profile schema>_<+schema>` ดังนั้นจะได้ **`dbt_raw`**, **`dbt_staging`**,
> **`dbt_intermediate`**, **`dbt_marts`**, **`dbt_aggregates`** และ **`dbt_reporting`**
> — จำชื่อสองตัวท้ายไว้ใช้ตอนต่อ Metabase ใน Part 9

**ตรวจการเชื่อมต่อ**

```bash
docker exec -it dw_dbt bash
cd lab8
dbt debug
```

<details>
<summary><b>Show Output — <code>dbt debug</code></b></summary>

![dbt debug output](./docs/screenshots/dbt-debug.png)

</details>

> ✅ **ผลที่ต้องได้:** `Connection test: OK` และ `All checks passed`

---

## 🌱 Part 3: Load Seeds & Build Staging Models / โหลด Seed และสร้าง Staging Models

### 3.1 โหลด CSV ด้วย `dbt seed`

ภายใน container `dw_dbt`:

```bash
dbt seed --full-refresh
dbt show --select coffee_sales
dbt show --select province_region_mapping_v2
```

<details>
<summary><b>Show Output — <code>dbt seed --full-refresh</code></b></summary>

![dbt seed output](./docs/screenshots/dbt-seed.png)

</details>

> ✅ **ผลที่คาดหวัง:** `coffee_sales` มี **3,000 แถว** และ `province_region_mapping_v2` มี **77 แถว**

---

### 3.2 ทำความสะอาดข้อมูลยอดขาย

`dbt/lab8/models/staging/stg_coffee_sales.sql`

```sql
select
    cast(sale_id as integer) as sale_id,
    trim(invoice_number) as invoice_number,
    cast(sale_date as date) as sale_date,
    trim(customer_code) as customer_code,
    trim(customer_name) as customer_name,
    trim(gender) as gender,
    cast(birth_year as integer) as birth_year,
    trim(product_code) as product_code,
    trim(product_name) as product_name,
    lower(trim(category)) as category,
    trim(size) as size,
    cast(unit_price as numeric(12,2)) as unit_price,
    cast(quantity as integer) as quantity,
    cast(revenue as numeric(14,2)) as revenue,
    trim(store_code) as store_code,
    trim(store_name) as store_name,
    trim(province) as province,
    trim(staff_code) as staff_code,
    trim(staff_name) as staff_name,
    trim(position) as position,
    nullif(trim(promo_code), '') as promo_code,
    nullif(trim(promo_desc), '') as promo_desc,
    coalesce(cast(points_redeemed as integer), 0) as points_redeemed
from {{ ref('coffee_sales') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/staging/stg_coffee_sales.sql`](./script/dbt/lab8/models/staging/stg_coffee_sales.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/staging/stg_coffee_sales.sql dbt/lab8/models/staging/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\staging\stg_coffee_sales.sql dbt\lab8\models\staging\
```

</details>

`dbt/lab8/models/staging/stg_province_region_mapping.sql`

```sql
select
    trim(province_name) as province_name,
    trim(region_name) as region_name
from {{ ref('province_region_mapping_v2') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/staging/stg_province_region_mapping.sql`](./script/dbt/lab8/models/staging/stg_province_region_mapping.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/staging/stg_province_region_mapping.sql dbt/lab8/models/staging/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\staging\stg_province_region_mapping.sql dbt\lab8\models\staging\
```

</details>

**รันเฉพาะ staging layer**

```bash
dbt run --select path:models/staging
dbt show --select stg_coffee_sales --limit 5
```

<details>
<summary><b>Show Output — staging layer</b></summary>

![dbt run staging](./docs/screenshots/dbt-run-staging.png)

</details>

> 📝 **`lower(trim(category))`** ทำให้ `dim_category` ไม่แตกเป็นสองแถวเมื่อไฟล์ต้นทาง
> สะกดตัวพิมพ์ใหญ่-เล็กต่างกัน และ **`coalesce(..., 0)`** ทำให้ `points_redeemed` เป็น
> measure ที่ `SUM` ได้เสมอ

---

## 🧱 Part 4: Build Dimensions & Fact Table / สร้าง Dimensions และ Fact Table ด้วย dbt

ส่วนนี้สร้าง **Snowflake Schema** จาก Lab 5 ใหม่ใน project แยก โดยใช้ **deterministic surrogate keys**
จาก `md5()` เพื่อให้รันซ้ำแล้วได้คีย์เดิม

### 4.1 Dimensions พื้นฐานจาก `coffee_sales`

`dbt/lab8/models/marts/dim_customer.sql`

```sql
select distinct
    md5(customer_code) as customer_key,
    customer_code,
    customer_name,
    gender,
    birth_year
from {{ ref('stg_coffee_sales') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_customer.sql`](./script/dbt/lab8/models/marts/dim_customer.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_customer.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_customer.sql dbt\lab8\models\marts\
```

</details>

`dbt/lab8/models/marts/dim_category.sql`

```sql
select distinct
    md5(category) as category_key,
    category as category_name
from {{ ref('stg_coffee_sales') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_category.sql`](./script/dbt/lab8/models/marts/dim_category.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_category.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_category.sql dbt\lab8\models\marts\
```

</details>

`dbt/lab8/models/marts/dim_product.sql`

```sql
select distinct
    md5(s.product_code || '|' || s.size) as product_key,
    s.product_code,
    s.product_name,
    c.category_key,
    s.size,
    s.unit_price
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_category') }} c
  on s.category = c.category_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_product.sql`](./script/dbt/lab8/models/marts/dim_product.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_product.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_product.sql dbt\lab8\models\marts\
```

</details>

`dbt/lab8/models/marts/dim_position.sql`

```sql
select distinct
    md5(position) as position_key,
    position as position_name
from {{ ref('stg_coffee_sales') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_position.sql`](./script/dbt/lab8/models/marts/dim_position.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_position.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_position.sql dbt\lab8\models\marts\
```

</details>

`dbt/lab8/models/marts/dim_staff.sql`

```sql
select distinct
    md5(s.staff_code) as staff_key,
    s.staff_code,
    s.staff_name,
    p.position_key
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_position') }} p
  on s.position = p.position_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_staff.sql`](./script/dbt/lab8/models/marts/dim_staff.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_staff.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_staff.sql dbt\lab8\models\marts\
```

</details>

`dbt/lab8/models/marts/dim_promotion.sql`

```sql
select distinct
    md5(promo_code) as promo_key,
    promo_code,
    promo_desc
from {{ ref('stg_coffee_sales') }}
where promo_code is not null
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_promotion.sql`](./script/dbt/lab8/models/marts/dim_promotion.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_promotion.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_promotion.sql dbt\lab8\models\marts\
```

</details>

> ⚠️ **`select distinct` จะสร้างคีย์ซ้ำทันทีถ้า attribute ของรหัสเดียวกันไม่ตรงกัน**
> เช่น `customer_code` เดียวมีสองชื่อ — ชุดข้อมูลนี้สะอาดอยู่แล้ว (`unique` test ใน Part 6
> จะจับให้ถ้าไม่สะอาด) แต่กับข้อมูลจริงต้องเลือกค่าตัวแทนด้วย `max()` หรือ `row_number()`

---

### 4.2 Geography Dimensions จาก mapping v2

`dbt/lab8/models/marts/dim_region.sql`

```sql
select distinct
    md5(region_name) as region_key,
    region_name
from {{ ref('stg_province_region_mapping') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_region.sql`](./script/dbt/lab8/models/marts/dim_region.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_region.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_region.sql dbt\lab8\models\marts\
```

</details>

`dbt/lab8/models/marts/dim_province.sql`

```sql
select distinct
    md5(m.province_name) as province_key,
    m.province_name,
    r.region_key
from {{ ref('stg_province_region_mapping') }} m
join {{ ref('dim_region') }} r
  on m.region_name = r.region_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_province.sql`](./script/dbt/lab8/models/marts/dim_province.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_province.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_province.sql dbt\lab8\models\marts\
```

</details>

---

### 4.3 สร้างร้านให้ครบทุกจังหวัดแบบ Declarative

โมเดล `dim_store` **รักษาร้านเดิม 3 แห่ง** และ **สร้างร้านจำลองอีก 1 แห่งเฉพาะจังหวัดที่ยังไม่มีร้าน**
โดย **ไม่ใช้** `INSERT` หรือ `UPDATE`

`dbt/lab8/models/marts/dim_store.sql`

```sql
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
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_store.sql`](./script/dbt/lab8/models/marts/dim_store.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_store.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_store.sql dbt\lab8\models\marts\
```

</details>

> 📝 **การแก้ไขจาก SQL เดิม:** ไฟล์ข้อมูลจริงใช้รหัสร้าน `ST01`, `ST02` และ `ST03`
> **ไม่ใช่** `ST001`–`ST003` โมเดลนี้จึงตรวจร้านเดิมจากข้อมูลด้วย `join` และใช้
> `is_generated` แทนการ hard-code รายชื่อรหัสร้าน

> 💡 **ผลลัพธ์:** `3 ร้านเดิม + 74 ร้านจำลอง = 77 แถว` และรหัสที่สร้างใหม่คือ
> `ST004`–`ST077` จึงไม่ชนกับ `ST01`–`ST03`

---

### 4.4 สร้าง Date Dimension ครอบคลุม 9 เดือน

`dbt/lab8/models/marts/dim_date.sql`

```sql
select
    to_char(d::date, 'YYYYMMDD')::integer as date_key,
    d::date as sale_date,
    extract(year from d)::integer as year,
    extract(quarter from d)::integer as quarter,
    extract(month from d)::integer as month,
    to_char(d, 'YYYY-MM') as year_month,
    extract(day from d)::integer as day_of_month
from generate_series(
    date '2024-07-01',
    date '2025-03-31',
    interval '1 day'
) as g(d)
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/dim_date.sql`](./script/dbt/lab8/models/marts/dim_date.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/dim_date.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\dim_date.sql dbt\lab8\models\marts\
```

</details>

> 💡 `2024-07-01` → `2025-03-31` คือ **274 วัน** (`184` วันในปี 2024 + `90` วันในปี 2025)

---

### 4.5 กำหนดร้านเป้าหมายให้แต่ละ Invoice

Invoice เดียวกันต้องอยู่ **ร้านเดียวกันทุก line item** จึงสร้าง mapping ที่ grain =
**หนึ่งแถวต่อ `invoice_number`** ก่อนขยายข้อมูลเป็นหลายเดือน

`dbt/lab8/models/intermediate/int_invoice_store_map.sql`

```sql
with generated_stores as (
    select
        store_code,
        row_number() over (order by store_code) as store_num,
        count(*) over () as store_count
    from {{ ref('dim_store') }}
    where is_generated
),

invoices as (
    select distinct invoice_number
    from {{ ref('stg_coffee_sales') }}
)

select
    i.invoice_number,
    g.store_code as target_store_code
from invoices i
join generated_stores g
  on g.store_num = (
      (hashtext(i.invoice_number)::bigint & 2147483647)
      % g.store_count
  ) + 1
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/intermediate/int_invoice_store_map.sql`](./script/dbt/lab8/models/intermediate/int_invoice_store_map.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/intermediate/int_invoice_store_map.sql dbt/lab8/models/intermediate/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\intermediate\int_invoice_store_map.sql dbt\lab8\models\intermediate\
```

</details>

> ⚠️ **`where is_generated`** หมายความว่าทุก invoice ถูกย้ายไปอยู่ **ร้านจำลอง 74 แห่ง**
> ดังนั้นร้านเดิม `ST01`–`ST03` จะ **ไม่มียอดขายใน `fct_sales`** — เป็นเจตนาของ Lab
> เพื่อกระจายข้อมูลให้ครบทุกภูมิภาค ไม่ใช่ข้อผิดพลาด

> 💡 **`hashtext(...) & 2147483647`** ตัดบิตเครื่องหมายทิ้งเพื่อให้ค่าเป็นบวกเสมอ ก่อนหาร
> เอาเศษกับจำนวนร้าน — ผลคือการกระจายที่ **คงที่ทุกครั้งที่รัน** (deterministic)

---

### 4.6 ขยายข้อมูลเดือน Jul 2024 ถึง Mar 2025

`dbt/lab8/models/intermediate/int_sales_expanded.sql`

```sql
with months as (
    select month_start::date
    from generate_series(
        date '2024-07-01',
        date '2025-03-01',
        interval '1 month'
    ) as g(month_start)
),

expanded as (
    select
        s.*,
        m.month_start,
        map.target_store_code,
        make_date(
            extract(year from m.month_start)::integer,
            extract(month from m.month_start)::integer,
            least(
                extract(day from s.sale_date)::integer,
                extract(day from (
                    date_trunc('month', m.month_start)
                    + interval '1 month - 1 day'
                ))::integer
            )
        ) as target_sale_date
    from {{ ref('stg_coffee_sales') }} s
    cross join months m
    join {{ ref('int_invoice_store_map') }} map
      on s.invoice_number = map.invoice_number
)

select
    md5(sale_id::text || '|' || month_start::text) as sale_key,
    sale_id as source_sale_id,
    case
        when month_start = date '2024-07-01' then invoice_number
        else invoice_number || '_' || to_char(month_start, 'YYYYMM')
    end as invoice_number,
    target_sale_date as sale_date,
    customer_code,
    product_code,
    size,
    target_store_code as store_code,
    staff_code,
    promo_code,
    quantity,
    revenue,
    points_redeemed
from expanded
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/intermediate/int_sales_expanded.sql`](./script/dbt/lab8/models/intermediate/int_sales_expanded.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/intermediate/int_sales_expanded.sql dbt/lab8/models/intermediate/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\intermediate\int_sales_expanded.sql dbt\lab8\models\intermediate\
```

</details>

> ⚠️ **วันที่ 29–31:** เมื่อขยายไปยังเดือนที่มีจำนวนวันน้อยกว่า โมเดลใช้ **วันสุดท้ายของ
> เดือนเป้าหมาย** เช่น `31 มกราคม` จะกลายเป็น `28 กุมภาพันธ์ 2025`

> 📝 **`invoice_number` ถูกเติมท้ายด้วย `_YYYYMM`** ทุกเดือนยกเว้นเดือนต้นฉบับ ทำให้
> `count(distinct invoice_number)` ของแต่ละเดือน **ไม่ทับกัน** — จุดนี้สำคัญกับ Roll-up ใน Part 7.1

---

### 4.7 สร้าง Fact Table

`dbt/lab8/models/marts/fct_sales.sql`

```sql
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
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/marts/fct_sales.sql`](./script/dbt/lab8/models/marts/fct_sales.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/marts/fct_sales.sql dbt/lab8/models/marts/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\marts\fct_sales.sql dbt\lab8\models\marts\
```

</details>

> ✅ **Grain ของ `fct_sales`:** หนึ่งแถวต่อ **รายการขายเดิมต่อเดือนเป้าหมาย** โดย `sale_key`
> ต้องไม่ซ้ำ และคาดหวัง **3,000 × 9 = 27,000 แถว**

> 📝 **`left join dim_promotion`** เพราะรายการที่ไม่มีโปรโมชันต้องยังอยู่ใน fact
> (`promo_key` เป็น `NULL` ได้)

---

## 📊 Part 5: Explore Granularity & Build the Summary Table / สำรวจ Granularity และสร้าง Summary Table

### 5.1 Transaction-level

สังเกตว่า `invoice_number` **หนึ่งใบอาจมีหลายแถว** เพราะแต่ละแถวแทน **สินค้าหนึ่งรายการ**
ในใบเสร็จ

```bash
dbt show --inline "
select
    invoice_number,
    count(*) as line_items,
    sum(revenue) as invoice_revenue
from {{ ref('fct_sales') }}
group by invoice_number
order by line_items desc, invoice_number
" --limit 10
```

<details>
<summary><b>Show Output — line items ต่อใบเสร็จ</b></summary>

![Line items per invoice](./docs/screenshots/dbt-show-transaction-level.png)

</details>

> 💡 ข้อมูลต้นฉบับมี **3,000 line items** จาก **1,501 ใบเสร็จ** — นี่คือเหตุผลที่
> `count(*)` และ `count(distinct invoice_number)` ให้คนละคำตอบ

---

### 5.2 Daily sales per store

`dbt/lab8/models/reporting/rpt_sales_store_day.sql`

```sql
select
    d.sale_date,
    s.store_key,
    s.store_code,
    s.store_name,
    sum(f.revenue) as daily_revenue,
    sum(f.quantity) as daily_quantity,
    count(distinct f.invoice_number) as invoice_count
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }} d
  on f.date_key = d.date_key
join {{ ref('dim_store') }} s
  on f.store_key = s.store_key
group by
    d.sale_date,
    s.store_key,
    s.store_code,
    s.store_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/reporting/rpt_sales_store_day.sql`](./script/dbt/lab8/models/reporting/rpt_sales_store_day.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/reporting/rpt_sales_store_day.sql dbt/lab8/models/reporting/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\reporting\rpt_sales_store_day.sql dbt\lab8\models\reporting\
```

</details>

---

### 5.3 Monthly sales per region: Aggregate Table

โมเดลนี้ materialized เป็น **table** ตาม `dbt_project.yml` เพื่อเก็บผลรวมที่ query บ่อย
ลดการ join fact กับ geography dimensions ซ้ำทุกครั้ง

`dbt/lab8/models/aggregates/agg_sales_region_month.sql`

```sql
{{
  config(
    indexes=[
      {'columns': ['month_start', 'region_key'], 'unique': true}
    ]
  )
}}

select
    date_trunc('month', d.sale_date)::date as month_start,
    r.region_key,
    r.region_name,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as total_quantity,
    sum(f.points_redeemed) as total_points_redeemed,
    count(distinct f.invoice_number) as invoice_count,
    count(*) as line_item_count
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }} d
  on f.date_key = d.date_key
join {{ ref('dim_store') }} s
  on f.store_key = s.store_key
join {{ ref('dim_province') }} p
  on s.province_key = p.province_key
join {{ ref('dim_region') }} r
  on p.region_key = r.region_key
group by
    date_trunc('month', d.sale_date)::date,
    r.region_key,
    r.region_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/aggregates/agg_sales_region_month.sql`](./script/dbt/lab8/models/aggregates/agg_sales_region_month.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/aggregates/agg_sales_region_month.sql dbt/lab8/models/aggregates/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\aggregates\agg_sales_region_month.sql dbt\lab8\models\aggregates\
```

</details>

> ✅ **Grain ของ Aggregate:** หนึ่งแถวต่อ `month_start` + `region_key` ส่วน `region_name`
> เป็น **descriptive attribute** ไม่ใช่ตัวกำหนด grain

> 💡 **`indexes=[... 'unique': true]`** ทำให้ฐานข้อมูลบังคับ grain ให้เอง — เป็นการป้องกัน
> ชั้นที่สองนอกเหนือจาก singular test ใน Part 6.2

---

### 5.4 Table หรือ View?

| Materialization   | ข้อดี                                                             | ข้อควรพิจารณา                                                    | ใช้ใน Lab                          |
| ----------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------ |
| `view`          | ข้อมูลใหม่ตาม upstream ทุกครั้งและไม่ซ้ำพื้นที่จัดเก็บ | query ซับซ้อนอาจช้าจากการคำนวณซ้ำ                     | staging, intermediate, reporting            |
| `table`         | อ่านเร็วและสร้าง index ได้                              | ต้อง `dbt run` / `dbt build` เพื่อ refresh                        | dimensions, fact, aggregate                 |
| `incremental`   | ประมวลผลเฉพาะข้อมูลใหม่                              | ต้องกำหนด `unique_key` และกลยุทธ์รับข้อมูลย้อนหลัง | หัวข้อต่อยอดหลัง Lab      |

---

## ✅ Part 6: Define Tests & Run the Pipeline / กำหนด Tests และรัน Pipeline

### 6.1 Generic Tests และ Documentation

`dbt/lab8/models/schema.yml`

<details>
<summary><b>📄 Full <code>schema.yml</code> — คลิกเพื่อดูทั้งไฟล์</b></summary>

```yaml
version: 2

seeds:
  - name: coffee_sales
    description: ข้อมูลขายเดือนกรกฎาคม 2024 จำนวน 3,000 line items
    columns:
      - name: sale_id
        tests: [not_null, unique]
  - name: province_region_mapping_v2
    description: Mapping 77 จังหวัดไปยัง 6 regions
    columns:
      - name: province_name
        tests: [not_null, unique]
      - name: region_name
        tests: [not_null]

models:
  - name: stg_coffee_sales
    description: Cleaned sales; grain คือหนึ่งแถวต่อ sale_id
    columns:
      - name: sale_id
        tests: [not_null, unique]
      - name: invoice_number
        tests: [not_null]
      - name: province
        tests: [not_null]

  - name: dim_region
    columns:
      - name: region_key
        tests: [not_null, unique]
      - name: region_name
        tests: [not_null, unique]

  - name: dim_province
    columns:
      - name: province_key
        tests: [not_null, unique]
      - name: province_name
        tests: [not_null, unique]
      - name: region_key
        tests:
          - not_null
          - relationships:
              to: ref('dim_region')
              field: region_key

  - name: dim_store
    columns:
      - name: store_key
        tests: [not_null, unique]
      - name: store_code
        tests: [not_null, unique]
      - name: province_key
        tests:
          - not_null
          - relationships:
              to: ref('dim_province')
              field: province_key

  - name: dim_date
    columns:
      - name: date_key
        tests: [not_null, unique]
      - name: sale_date
        tests: [not_null, unique]

  - name: fct_sales
    description: Fact ที่ขยายข้อมูลเดิมเป็น 9 เดือน
    columns:
      - name: sale_key
        tests: [not_null, unique]
      - name: date_key
        tests:
          - not_null
          - relationships:
              to: ref('dim_date')
              field: date_key
      - name: store_key
        tests:
          - not_null
          - relationships:
              to: ref('dim_store')
              field: store_key
      - name: revenue
        tests: [not_null]

  - name: agg_sales_region_month
    description: Summary table; grain คือหนึ่งเดือนต่อหนึ่ง region
    columns:
      - name: month_start
        tests: [not_null]
      - name: region_key
        tests:
          - not_null
          - relationships:
              to: ref('dim_region')
              field: region_key
      - name: total_revenue
        tests: [not_null]
      - name: total_quantity
        tests: [not_null]
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/schema.yml`](./script/dbt/lab8/models/schema.yml)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/schema.yml dbt/lab8/models/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\schema.yml dbt\lab8\models\
```

</details>

</details>

---

### 6.2 Singular Tests สำหรับกฎทางธุรกิจ

`dbt/lab8/tests/assert_all_provinces_have_store.sql`

```sql
select p.*
from {{ ref('dim_province') }} p
left join {{ ref('dim_store') }} s
  on p.province_key = s.province_key
where s.store_key is null
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/tests/assert_all_provinces_have_store.sql`](./script/dbt/lab8/tests/assert_all_provinces_have_store.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/tests/assert_all_provinces_have_store.sql dbt/lab8/tests/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\tests\assert_all_provinces_have_store.sql dbt\lab8\tests\
```

</details>

`dbt/lab8/tests/assert_fact_expected_row_count.sql`

```sql
select count(*) as actual_rows
from {{ ref('fct_sales') }}
having count(*) <> 27000
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/tests/assert_fact_expected_row_count.sql`](./script/dbt/lab8/tests/assert_fact_expected_row_count.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/tests/assert_fact_expected_row_count.sql dbt/lab8/tests/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\tests\assert_fact_expected_row_count.sql dbt\lab8\tests\
```

</details>

`dbt/lab8/tests/assert_summary_grain.sql`

```sql
select
    month_start,
    region_key,
    count(*) as duplicate_rows
from {{ ref('agg_sales_region_month') }}
group by month_start, region_key
having count(*) > 1
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/tests/assert_summary_grain.sql`](./script/dbt/lab8/tests/assert_summary_grain.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/tests/assert_summary_grain.sql dbt/lab8/tests/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\tests\assert_summary_grain.sql dbt\lab8\tests\
```

</details>

`dbt/lab8/tests/assert_summary_reconciles.sql`

```sql
with fact_total as (
    select
        sum(revenue) as revenue,
        sum(quantity) as quantity,
        sum(points_redeemed) as points
    from {{ ref('fct_sales') }}
),

summary_total as (
    select
        sum(total_revenue) as revenue,
        sum(total_quantity) as quantity,
        sum(total_points_redeemed) as points
    from {{ ref('agg_sales_region_month') }}
)

select
    f.revenue as fact_revenue,
    s.revenue as summary_revenue,
    f.quantity as fact_quantity,
    s.quantity as summary_quantity,
    f.points as fact_points,
    s.points as summary_points
from fact_total f
cross join summary_total s
where abs(f.revenue - s.revenue) > 0.01
   or f.quantity <> s.quantity
   or f.points <> s.points
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/tests/assert_summary_reconciles.sql`](./script/dbt/lab8/tests/assert_summary_reconciles.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/tests/assert_summary_reconciles.sql dbt/lab8/tests/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\tests\assert_summary_reconciles.sql dbt\lab8\tests\
```

</details>

> ✅ **Singular test ต้องคืนค่า 0 แถวจึงจะผ่าน** — หากมีผลลัพธ์ แถวนั้นคือ **หลักฐานของปัญหา**
> ที่ต้องตรวจสอบ

> 💡 **`assert_summary_reconciles`** คือหัวใจของ Lab นี้ — พิสูจน์ว่า summary table
> **กระทบยอด** กับ fact table ได้ทุกบาททุกชิ้น (ใช้ `abs(...) > 0.01` เผื่อความคลาดเคลื่อน
> ของ floating point)

---

### 6.3 รัน Pipeline ด้วยคำสั่งเดียว

```bash
dbt build
```

<details>
<summary><b>Show Output — <code>dbt build</code></b></summary>

![dbt build output](./docs/screenshots/dbt-build.png)

</details>

> 📝 `dbt build` จะ **seed → สร้าง models → รัน tests** ตาม **dependency graph** ที่เกิดจาก `ref()`

**ตรวจจำนวนแถวสำคัญ**

```bash
dbt show --inline "
select 'dim_region' as model, count(*) as row_count from {{ ref('dim_region') }}
union all select 'dim_province', count(*) from {{ ref('dim_province') }}
union all select 'dim_store', count(*) from {{ ref('dim_store') }}
union all select 'dim_date', count(*) from {{ ref('dim_date') }}
union all select 'fct_sales', count(*) from {{ ref('fct_sales') }}
union all select 'agg_sales_region_month', count(*)
from {{ ref('agg_sales_region_month') }}
" --limit 6
```

> ⚠️ **ใบ Lab พิมพ์ `–limit 6` ด้วยขีดยาว (en dash)** ซึ่ง shell จะไม่รู้จัก — ต้องพิมพ์เป็น
> **`--limit 6`** ด้วยขีดสั้นสองตัว

<details>
<summary><b>Show Output — row counts</b></summary>

![Row counts across models](./docs/screenshots/dbt-show-row-counts.png)

</details>

| Model                        | จำนวนที่คาดหวัง | เหตุผล                                                       |
| ---------------------------- | ---------------------: | ------------------------------------------------------------------ |
| `dim_region`               |                      6 | 6 regions ใน mapping v2                                       |
| `dim_province`             |                     77 | หนึ่งแถวต่อจังหวัด                              |
| `dim_store`                |                     77 | หนึ่งร้านต่อจังหวัดหลังรวมร้านเดิมและร้านจำลอง |
| `dim_date`                 |                    274 | `2024-07-01` ถึง `2025-03-31`                              |
| `fct_sales`                |                 27,000 | 3,000 แถว × 9 เดือน                                       |
| `agg_sales_region_month`   |                     54 | 9 เดือน × 6 regions เมื่อทุก region มียอดขาย     |

---

## 🧊 Part 7: Build the OLAP Models / สร้าง OLAP Models

### 7.1 Roll-up: เดือน → ไตรมาส

**Roll-up** ใช้ **aggregate table รายเดือน** เป็นต้นทาง จึง **ไม่ต้องอ่าน fact table**
และ join dimensions ใหม่

`dbt/lab8/models/reporting/rpt_sales_region_quarter.sql`

```sql
select
    date_trunc('quarter', month_start)::date as quarter_start,
    region_key,
    region_name,
    sum(total_revenue) as quarter_revenue,
    sum(total_quantity) as quarter_quantity,
    sum(total_points_redeemed) as quarter_points_redeemed,
    sum(invoice_count) as quarter_invoice_count
from {{ ref('agg_sales_region_month') }}
group by
    date_trunc('quarter', month_start)::date,
    region_key,
    region_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/reporting/rpt_sales_region_quarter.sql`](./script/dbt/lab8/models/reporting/rpt_sales_region_quarter.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/reporting/rpt_sales_region_quarter.sql dbt/lab8/models/reporting/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\reporting\rpt_sales_region_quarter.sql dbt\lab8\models\reporting\
```

</details>

> ✅ **ข้อสังเกต:** `revenue`, `quantity` และ `points_redeemed` เป็น **additive** จึง `SUM`
> ต่อได้ ส่วน **ค่าเฉลี่ยหรือเปอร์เซ็นต์** ต้องกลับไปคำนวณจาก **numerator และ denominator**
> ที่เก็บไว้

> 💡 **ทำไม `sum(invoice_count)` ถึงถูกต้องที่นี่:** โดยทั่วไป `count(distinct ...)`
> **รวมข้ามกลุ่มไม่ได้** แต่ Part 4.6 เติมท้าย `invoice_number` ด้วย `_YYYYMM` ทุกเดือน
> ใบเสร็จจึง **ไม่ทับกันข้ามเดือน** — ถ้าข้อมูลจริงมีใบเสร็จเดียวข้ามหลายเดือน
> ต้องกลับไป `count(distinct ...)` จาก fact table แทน

---

### 7.2 Drill-down: Region → Province

Aggregate รายเดือนต่อ region **ไม่มี `province_key`** จึง drill-down จากตารางนั้นโดยตรงไม่ได้
ต้อง **อ่าน fact table** แล้ว group ที่ grain ละเอียดกว่า

`dbt/lab8/models/reporting/rpt_sales_province_quarter.sql`

```sql
select
    date_trunc('quarter', d.sale_date)::date as quarter_start,
    r.region_key,
    r.region_name,
    p.province_key,
    p.province_name,
    sum(f.revenue) as province_revenue,
    sum(f.quantity) as province_quantity,
    count(distinct f.invoice_number) as invoice_count
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }} d
  on f.date_key = d.date_key
join {{ ref('dim_store') }} s
  on f.store_key = s.store_key
join {{ ref('dim_province') }} p
  on s.province_key = p.province_key
join {{ ref('dim_region') }} r
  on p.region_key = r.region_key
group by
    date_trunc('quarter', d.sale_date)::date,
    r.region_key,
    r.region_name,
    p.province_key,
    p.province_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/reporting/rpt_sales_province_quarter.sql`](./script/dbt/lab8/models/reporting/rpt_sales_province_quarter.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/reporting/rpt_sales_province_quarter.sql dbt/lab8/models/reporting/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\reporting\rpt_sales_province_quarter.sql dbt\lab8\models\reporting\
```

</details>

> 📝 **บทเรียนสำคัญ:** aggregate table เร็วขึ้นได้เพราะ **ตัดมิติทิ้ง** — มิติที่ตัดทิ้งแล้ว
> จะ drill-down กลับไม่ได้ ต้องออกแบบว่าจะเก็บ grain ระดับไหนตั้งแต่ต้น

---

### 7.3 CUBE: Year × Staff

`dbt/lab8/models/reporting/rpt_sales_staff_year_cube.sql`

```sql
select
    d.year,
    f.staff_key,
    grouping(d.year) as is_all_years,
    grouping(f.staff_key) as is_all_staff,
    sum(f.revenue) as total_revenue,
    sum(f.quantity) as total_quantity
from {{ ref('fct_sales') }} f
join {{ ref('dim_date') }} d
  on f.date_key = d.date_key
group by cube(d.year, f.staff_key)
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

รันจาก root (`lab-week01/` หรือ `DWH_Lab/`) — ต้นทางคือ [`script/dbt/lab8/models/reporting/rpt_sales_staff_year_cube.sql`](./script/dbt/lab8/models/reporting/rpt_sales_staff_year_cube.sql)

**Mac / Linux:**

```bash
cp ../../week08-aggregation-summary-table-with-dbt/script/dbt/lab8/models/reporting/rpt_sales_staff_year_cube.sql dbt/lab8/models/reporting/
```

**Windows (PowerShell):**

```powershell
Copy-Item ..\..\week08-aggregation-summary-table-with-dbt\script\dbt\lab8\models\reporting\rpt_sales_staff_year_cube.sql dbt\lab8\models\reporting\
```

</details>

| `is_all_years` | `is_all_staff` | ความหมายของแถว                        |
| :--------------: | :--------------: | ---------------------------------------------- |
|        0         |        0         | ยอดของ staff แต่ละคนในแต่ละปี |
|        0         |        1         | ยอดรวม staff ทุกคนในปีนั้น       |
|        1         |        0         | ยอดรวมทุกปีของ staff คนนั้น      |
|        1         |        1         | **Grand total** ทุกปีและทุก staff  |

> 💡 **`grouping(col)`** คืน `1` เมื่อคอลัมน์นั้นถูก **ยุบ** ใน subtotal แถวนั้น — ใช้แยก
> ระดับ subtotal ออกจากแถวรายละเอียดได้ โดยไม่ต้องเดาจากค่า `NULL`

**สร้างและตรวจ OLAP models**

```bash
dbt run --select path:models/reporting
dbt show --select rpt_sales_region_quarter --limit 30
dbt show --select rpt_sales_province_quarter --limit 30
dbt show --select rpt_sales_staff_year_cube --limit 30
```

<details>
<summary><b>Show Output — Roll-up (region × quarter)</b></summary>

![Roll-up region by quarter](./docs/screenshots/dbt-show-region-quarter.png)

</details>

<details>
<summary><b>Show Output — Drill-down (province × quarter)</b></summary>

![Drill-down province by quarter](./docs/screenshots/dbt-show-province-quarter.png)

</details>

<details>
<summary><b>Show Output — CUBE (staff × year)</b></summary>

![CUBE staff by year](./docs/screenshots/dbt-show-staff-year-cube.png)

</details>

---

## 📚 Part 8: Generate dbt Documentation & Check Lineage / สร้าง dbt Documentation และตรวจ Lineage

```bash
dbt docs generate
dbt docs serve --host 0.0.0.0 --port 8080
```

<details>
<summary><b>Show Output — <code>dbt docs generate</code></b></summary>

![dbt docs generate](./docs/screenshots/dbt-docs-generate.png)

</details>

เปิด [http://localhost:28088](http://localhost:28088) แล้วค้นหา `agg_sales_region_month`
จากนั้นเปิด **Lineage Graph**:

- ตรวจ **upstream:** seeds → staging → dimensions/intermediate → `fct_sales`
- ตรวจ **downstream:** `agg_sales_region_month` → `rpt_sales_region_quarter`
- เปิดแท็บ **Tests** เพื่อดู generic tests และ singular tests ที่เชื่อมกับโมเดล

<details>
<summary><b>📷 dbt docs — Lineage Graph ของ <code>agg_sales_region_month</code></b></summary>

![dbt docs lineage graph](./docs/screenshots/dbt-docs-lineage.png)

</details>

> 📝 **To reach the docs site from your browser**, the `dbt` service in `docker-compose` must map the
> port — `ports: ["28088:8080"]`. `dbt docs serve` runs until you press **Ctrl+C**.

> 💡 **เหตุผลที่ใช้ dbt docs:** คำอธิบาย grain, คอลัมน์, tests, compiled SQL และ dependency
> จาก `ref()` ถูกรวมไว้ในจุดเดียว ทำให้ตรวจ **เส้นทางของ summary table กลับไปยังข้อมูลต้นทาง** ได้

---

## 📈 Part 9: Build the Dashboard on Metabase / สร้าง Dashboard บน Metabase

### 9.1 เชื่อมต่อ PostgreSQL

เปิด [http://localhost:23000](http://localhost:23000) แล้วเพิ่มฐานข้อมูลด้วยค่าต่อไปนี้:

| ค่า                     | กำหนดเป็น          |
| ----------------------------- | -------------------------- |
| Database type                 | PostgreSQL                 |
| Host                          | `postgres`               |
| Port                          | `5432`                   |
| Database name                 | `lab8`                   |
| Username / Password           | `dw_user` / `dw_pass`  |

<details>
<summary><b>📷 Metabase — เพิ่มฐานข้อมูล <code>lab8</code></b></summary>

![Metabase add database](./docs/screenshots/metabase-add-database.png)

</details>

> ⚠️ **หากยังไม่เห็น `dbt_aggregates` และ `dbt_reporting`** ให้สั่ง **Sync database schema**
> ที่หน้า Admin ➡️ Databases ➡️ `lab8`

---

### 9.2 สร้างคำถามสำหรับ Roll-up

1. เลือก `dbt_reporting.rpt_sales_region_quarter`
2. แสดง **Line chart:** X-axis = `quarter_start`, Y-axis = `quarter_revenue`,
   Breakout = `region_name`
3. บันทึกชื่อ **Revenue by Quarter and Region**

<details>
<summary><b>📷 Metabase — Revenue by Quarter and Region</b></summary>

![Revenue by quarter and region](./docs/screenshots/metabase-revenue-quarter-region.png)

</details>

---

### 9.3 สร้างคำถามสำหรับ Drill-down

1. เลือก `dbt_reporting.rpt_sales_province_quarter`
2. เพิ่ม filters `quarter_start` และ `region_name`
3. แสดง **Bar chart:** X-axis = `province_name`, Y-axis = `province_revenue`
4. บันทึกชื่อ **Revenue by Province**

<details>
<summary><b>📷 Metabase — Revenue by Province</b></summary>

![Revenue by province](./docs/screenshots/metabase-revenue-province.png)

</details>

---

### 9.4 ประกอบ Dashboard

1. สร้าง Dashboard ชื่อ **Sales Roll-up and Drill-down**
2. เพิ่มการ์ด **Revenue by Quarter and Region** และ **Revenue by Province**
3. เพิ่ม **Dashboard filters: Quarter และ Region** แล้ว map เข้ากับ **ทั้งสองการ์ด**
4. เลือก region หนึ่งค่าเพื่อตรวจว่า Province chart แสดงรายละเอียด **เฉพาะ region ที่เลือก**
5. เพิ่มตารางจาก `rpt_sales_staff_year_cube` และใช้ `is_all_years` / `is_all_staff`
   แยกระดับ subtotal

<details>
<summary><b>📷 Metabase — Dashboard "Sales Roll-up and Drill-down"</b></summary>

![Sales roll-up and drill-down dashboard](./docs/screenshots/metabase-dashboard.png)

</details>

---

## 📤 Submission / สิ่งที่ต้องส่ง

ส่งคำตอบผ่าน **[Google Form — Lab 8: Granularity, Aggregation & Summary Table](https://docs.google.com/forms/d/1eteh4t-KMlqZiQzsH0rZBNJah8qzZPC-VGHh40daEDY/viewform)**

| รายการ    | รูปแบบ                             |
| ---------------- | ---------------------------------------- |
| **Dashboard** | Screenshot ส่งใน Google Form |

> 📝 Dashboard ที่ส่งควรเห็นครบทั้ง **Roll-up chart**, **Drill-down chart** และ **filters
> ที่ map แล้ว** ตาม Part 9.4

---

## 🛠️ dbt Cheat Sheet

> ⚠️ เปิด shell ใน container ก่อน — `docker exec -it dw_dbt bash` แล้ว `cd lab8`
> เพื่อไม่ให้ Jinja ใน `--inline` ถูก host shell แปลงค่า

| Command                                             | Description                                        |
| --------------------------------------------------- | -------------------------------------------------- |
| `docker exec -it dw_dbt bash`                     | Open a shell inside the dbt container              |
| `dbt debug`                                       | Test the database connection                       |
| `dbt seed --full-refresh`                         | Rebuild both seed tables from the CSVs             |
| `dbt run --select path:models/staging`            | Build the two staging views                        |
| `dbt run --select path:models/marts`              | Build the 10 dimensions + `fct_sales`            |
| `dbt run --select path:models/aggregates`         | Build the summary table                            |
| `dbt run --select path:models/reporting`          | Build the Roll-up / Drill-down / CUBE views        |
| `dbt build`                                       | Run seeds + models + all tests in dependency order |
| `dbt test`                                        | Run the data tests only                            |
| `dbt test --select agg_sales_region_month`        | Run only the summary table's tests                 |
| `dbt ls --resource-type model`                    | List every model in the project                    |
| `dbt show --select <model> --limit 30`            | Preview a model's rows                             |
| `dbt run --select agg_sales_region_month+`        | Rebuild the aggregate **and everything downstream** |
| `dbt docs generate`                               | Build the documentation site                       |
| `dbt docs serve --host 0.0.0.0 --port 8080`       | Serve the docs on port 8080                        |

---

## 🧾 Granularity & OLAP Quick Reference

|      Operation      | ทำอะไร                                                | ต้นทางใน Lab                     | โมเดล                          |
| :-----------------: | ------------------------------------------------------------- | --------------------------------------- | ------------------------------------- |
| **Roll-up**   | ยุบ grain ให้หยาบขึ้น (เดือน → ไตรมาส) | `agg_sales_region_month`              | `rpt_sales_region_quarter`          |
| **Drill-down** | ลง grain ให้ละเอียดขึ้น (region → province) | `fct_sales` (aggregate ไม่มี province) | `rpt_sales_province_quarter`        |
| **CUBE**      | สร้าง subtotal ทุกชุดค่าผสมของมิติ    | `fct_sales`                           | `rpt_sales_staff_year_cube`         |
| **Slice / Dice** | กรองหนึ่งมิติ / หลายมิติ                | Metabase filters                        | Dashboard `Quarter` + `Region`    |

| Additivity          | รวมได้เมื่อไร                          | ตัวอย่างใน Lab                                        |
| ------------------- | ------------------------------------------------ | -------------------------------------------------------------- |
| **Additive**  | รวมได้ทุกมิติ                       | `revenue`, `quantity`, `points_redeemed`, `line_item_count` |
| **Semi-additive** | รวมข้ามมิติได้ ยกเว้นเวลา | ยอดคงเหลือ/สต๊อก (ไม่มีใน Lab นี้)      |
| **Non-additive** | ต้องคำนวณใหม่จากตัวตั้ง/ตัวหาร | ยอดเฉลี่ยต่อใบเสร็จ, % ส่วนแบ่ง, `count(distinct ...)` โดยทั่วไป |

---

*Data Warehouse — DSBA8 | Week 8*

# 📦 Week 9: ETL — Incremental Load & SCD Type 2

> **Course:** Data Warehousing (การสร้างคลังข้อมูล)  
> **Topic:** ETL แบบ Incremental Load + SCD Type 2 ด้วย dbt  
> **Duration:** 2 Hours

> 💡 **Lab concept / แนวคิดหลัก:** โหลดข้อมูลขายเดือนเดียวกัน **2 batch** เข้า fact table
> เดิมโดย **ไม่เกิดแถวซ้ำ** (incremental) และระหว่างนั้นลูกค้า `CUST-1007` **เปลี่ยนชื่อ**
> จาก `Arthit` เป็น `Tawon` — ต้องเก็บทั้งสองเวอร์ชันไว้ด้วย **SCD Type 2** (`dbt snapshot`)
> โดยที่ยอดขายเก่ายังผูกกับชื่อเก่าอยู่

> 📷 The screenshot blocks below point at `docs/screenshots/`. Capture each output as you run the
> lab and drop the PNGs there — filenames already match.

---

## 🎯 Learning Objectives / วัตถุประสงค์

1. สร้าง dbt project ใหม่ชื่อ **`lab9`** และฐานข้อมูล **`lab9`** พร้อม profile ของตัวเองได้
2. สร้าง **Snowflake Schema** ทั้งชุด (geography / product / staff hierarchy) จากไฟล์ CSV ด้วย dbt ได้
3. โหลดข้อมูลขายแบบ **incremental 2 batch** ด้วย `materialized='incremental'` โดยไม่เกิด fact ซ้ำ
4. จัดการ `dim_customer` แบบ **SCD Type 2** ด้วย `dbt snapshot` และผูก fact กับ **version ที่มีผลในวันขาย**
5. ใช้ **Jinja variable** (`--vars`) ควบคุมขอบเขตข้อมูลของแต่ละ batch ได้
6. ตรวจสอบผลด้วย **`dbt test`**, **`dbt show`** และ **`dbt docs`** ได้

---

## 🧰 Tools & Stack Overview / เครื่องมือที่ใช้

| Tool                            | What is it?              | หน้าที่ใน Lab                                                     |
| ------------------------------- | ------------------------ | -------------------------------------------------------------------------- |
| **PostgreSQL 16**         | Relational Database      | เก็บ seed, staging, snapshot, dimensions และ fact table             |
| **dbt-postgres**          | Transformation Framework | `seed`, `run`, `snapshot`, `test`, `docs` และ lineage         |
| **Docker Compose**        | Containerization         | เปิด services`postgres`, `pgadmin` และ `dbt`                  |
| **pgAdmin 4**             | DB management UI         | สร้างฐานข้อมูล`lab9` และตรวจผลด้วย Query Tool |
| **VS Code / Text Editor** | Editor                   | สร้างไฟล์ SQL และ YAML ในโครงการ dbt                  |

**Dataset / ชุดข้อมูล**

| Dataset                            | Rows | รายละเอียด                                                                           |
| ---------------------------------- | ---: | ---------------------------------------------------------------------------------------------- |
| `coffee_sales_scd_new.csv`       |   80 | รายการขาย`2031-04-01` → `2031-04-30` (ลูกค้า 10 คน, ร้าน 6 สาขา) |
| `province_region_mapping_v2.csv` |   77 | 77 จังหวัด แบ่งเป็น**6 regions** (ไฟล์เดียวกับ Lab 8)         |

**สถานการณ์ข้อมูล / Data scenario**

| Batch             | เงื่อนไข            | แถว | ช่วงวันที่             |
| ----------------- | --------------------------- | -----: | -------------------------------- |
| **Batch 1** | `sale_date <  2031-04-15` |     40 | `2031-04-01` → `2031-04-14` |
| **Batch 2** | `sale_date >= 2031-04-15` |     40 | `2031-04-15` → `2031-04-30` |

> 📝 **ไม่ต้องสร้างข้อมูลจำลองเพิ่ม** — ข้อมูลจริงมี `CUST-1007` เปลี่ยนชื่อจาก **`Arthit`**
> เป็น **`Tawon`** ใน Batch 2 (ขายวันที่ `2031-04-30`) จึงใช้สาธิต SCD Type 2 ได้ทันที

---

## 📁 Files in This Week / ไฟล์ในสัปดาห์นี้

| File / Folder                                                                                                                                         | Description                                                                                                                                              |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 📂[docs/](./docs/)                                                                                                                                     | Lab instructions                                                                                                                                         |
| ├── 📝[Lab9 ETL-Incremental + SCD with dbt.docx](<./docs/Lab9%20ETL-Incremental%20%2B%20SCD%20with%20dbt.docx>)                                     | Lab instruction (Word)                                                                                                                                   |
| ├── 📄[Lab9 ETL-Incremental + SCD with dbt.pdf](<./docs/Lab9%20ETL-Incremental%20%2B%20SCD%20with%20dbt.pdf>)                                       | Lab instruction (PDF)                                                                                                                                    |
| └── 📂[screenshots/](./docs/screenshots/)                                                                                                           | Images referenced by this README                                                                                                                         |
| 📂[script/](./script/)                                                                                                                                 | **ไฟล์ `.sql` / `.yml` ทั้งหมดของ Lab เตรียมไว้ให้** — ใช้กับ "คำสั่งลัด" ในแต่ละหัวข้อ |
| 📂[lab-week09/](./lab-week09/)                                                                                                                         | **Lab working directory**                                                                                                                          |
| ├── 📂[dbt_root/](./lab-week09/dbt_root/)                                                                                                           | Holds`profiles.yml` — the dbt connection profile                                                                                                      |
| │&nbsp;&nbsp;&nbsp;└── ⚙️ [profiles.yml](./lab-week09/dbt_root/profiles.yml)                                                                     | Connects dbt to PostgreSQL, database`lab9`                                                                                                             |
| └── 📂[dbt/lab9/](./lab-week09/dbt/lab9/)                                                                                                           | dbt project — models, snapshot & tests are created during the lab                                                                                       |
| &nbsp;&nbsp;&nbsp;&nbsp;├── ⚙️ [dbt_project.yml](./lab-week09/dbt/lab9/dbt_project.yml)                                                           | Materializations + schemas per folder                                                                                                                    |
| &nbsp;&nbsp;&nbsp;&nbsp;└── 📂 [seeds/](./lab-week09/dbt/lab9/seeds/)                                                                               | Seed CSVs, already in place                                                                                                                              |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├── 📊 [coffee_sales_scd_new.csv](./lab-week09/dbt/lab9/seeds/coffee_sales_scd_new.csv)             | 80 sales rows, April 2031                                                                                                                                |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└── 📊 [province_region_mapping_v2.csv](./lab-week09/dbt/lab9/seeds/province_region_mapping_v2.csv) | 77 provinces → 6 regions                                                                                                                                |

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

## 🧩 Part 1: Plan the Incremental Load / วางแผนการโหลดแบบ Incremental

### 1.1 แบ่งข้อมูลเป็น 2 batch

ข้อมูลใน CSV เป็นเดือนเดียวกันทั้งก้อน — Lab นี้จำลองว่า **ระบบต้นทางส่งมา 2 รอบ** โดยใช้
`sale_date` เป็นเส้นแบ่ง แล้วควบคุมด้วย Jinja variable ชื่อ `load_batch`

| รอบโหลด    | `--vars`                        | เงื่อนไขใน model  | แถวที่เข้ามา | fct_sales สะสม |
| ----------------- | --------------------------------- | --------------------------- | -----------------------: | -----------------: |
| **Batch 1** | `{"load_batch": "initial"}`     | `sale_date <  2031-04-15` |                       40 |       **40** |
| **Batch 2** | `{"load_batch": "incremental"}` | `sale_date >= 2031-04-15` |                       40 |       **80** |

> 💡 **หัวใจของ Incremental Load:** โหลดรอบที่ 2 **ต้องไม่ลบของเก่าและไม่เพิ่มของซ้ำ** —
> ในโมเดลนี้ป้องกันสองชั้น คือ `unique_key='sale_id'` + `incremental_strategy='merge'`
> และ `where not exists (select 1 from {{ this }} ...)` ใน Part 6.2

### 1.2 เลือกกลยุทธ์ให้แต่ละตาราง *(worksheet)*

ก่อนเขียน SQL ให้เติมช่องขวาสุดเองว่าแต่ละตารางควรโหลดแบบใด แล้วเทียบกับสิ่งที่ Lab สร้างจริงใน Part 3–6

| ตาราง                                      | เปลี่ยนแปลงบ่อยแค่ไหน         | ต้องเก็บประวัติไหม | กลยุทธ์ที่เลือก |
| ----------------------------------------------- | -------------------------------------------------- | ------------------------------------ | ------------------------------ |
| `stg_coffee_sales`, `stg_province_region`   | สร้างใหม่จาก seed ทุกครั้ง     | ไม่                               |                                |
| `dim_region`, `dim_province`, `dim_store` | แทบไม่เปลี่ยน                         | ไม่                               |                                |
| `dim_product`, `dim_category`               | เปลี่ยนบ้าง (ราคา/ชื่อ)         | ไม่ (Lab นี้)                  |                                |
| `dim_customer`                                | **ชื่อลูกค้าเปลี่ยนได้** | **ใช่**                     |                                |
| `fct_sales`                                   | เพิ่มขึ้นทุก batch                     | ไม่ (append)                      |                                |

<details>
<summary><b>เฉลย — กลยุทธ์ที่ Lab นี้ใช้จริง</b></summary>

| ตาราง              | Materialization / กลไก                             | เหตุผล                                                                                |
| ----------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| staging models          | `view`                                               | อ่านจาก seed ตรง ๆ ไม่ต้องเก็บผลลัพธ์                          |
| dimensions ทั่วไป | `table` (full refresh ทุก run)                    | ข้อมูลน้อยและ surrogate key เป็น`md5()` จึงไม่เปลี่ยนค่า |
| `dim_customer`        | `table` ที่อ่านจาก **snapshot**      | ต้องมีหลาย version ต่อหนึ่ง`customer_code` (SCD Type 2)                 |
| `snap_customer_scd`   | `dbt snapshot` (`strategy='check'`)                | dbt เป็นคนเปิด/ปิดช่วงเวลาให้เอง                                 |
| `fct_sales`           | `incremental` + `merge` + `unique_key='sale_id'` | ต่อท้ายทีละ batch โดยไม่ซ้ำและไม่ลบของเก่า               |

</details>

---

## 📥 Part 2: Prepare the Lab Environment / เตรียม Lab Environment

### 2.1 สร้างฐานข้อมูล

ใน pgAdmin ➡️ Query Tool (หรือ psql) รันคำสั่ง:

```sql
CREATE DATABASE lab9;
```

> ⚠️ **ใบ Lab เขียนชื่อฐานข้อมูลไม่ตรงกันเอง** — หัวข้อวัตถุประสงค์และย่อหน้าใน §1 เขียนว่า
> `lab9_dw` แต่คำสั่ง SQL จริงคือ `CREATE DATABASE lab9;` และ `profiles.yml` ใน §1.1 ก็ใช้
> `dbname: lab9` — README นี้ใช้ **`lab9`** ตลอดทั้งไฟล์ให้ตรงกับ SQL และ profile

> 💡 **ทางเลือกจาก Terminal** (เหมือนกันทุก OS):

```bash
docker exec -it dw_postgres psql -U dw_user -d airflow -c "CREATE DATABASE lab9;"
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
    └── lab9/
        ├── dbt_project.yml
        ├── seeds/
        │   ├── coffee_sales_scd_new.csv
        │   └── province_region_mapping_v2.csv
        ├── snapshots/
        │   └── snap_customer_scd.sql
        ├── models/
        │   ├── staging/
        │   │   ├── stg_coffee_sales.sql
        │   │   └── stg_province_region.sql
        │   ├── intermediate/
        │   │   ├── int_customer_source.sql
        │   │   └── int_sales_batch.sql
        │   ├── marts/
        │   │   ├── dim_region.sql
        │   │   ├── dim_province.sql
        │   │   ├── dim_store.sql
        │   │   ├── dim_category.sql
        │   │   ├── dim_product.sql
        │   │   ├── dim_position.sql
        │   │   ├── dim_staff.sql
        │   │   ├── dim_promotion.sql
        │   │   ├── dim_date.sql
        │   │   ├── dim_customer.sql
        │   │   └── fct_sales.sql
        │   └── schema.yml
        └── tests/
            ├── assert_fct_sales_unique_sale_id.sql
            ├── assert_customer_one_current_version.sql
            └── assert_all_sale_provinces_mapped.sql
```

> ⚠️ **root อยู่ที่ไหน — ใบ Lab เรียกว่า `DWH_Lab` แต่ในรีโปนี้ชื่อ `lab-week01`**
> `docker-compose.yaml` mount แบบ **relative กับตำแหน่งของตัวมันเอง** (`./dbt:/usr/app` และ
> `./dbt_root:/root/.dbt`) ดังนั้น `dbt/` และ `dbt_root/` ต้องอยู่ **ข้าง ๆ** `docker-compose.yaml`
> เสมอ ไม่ว่าโฟลเดอร์นั้นจะชื่ออะไร
>
> | สถานะของคุณ                                             | root คือ                                                                                                              |
> | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
> | ทำต่อจาก Week 1 มาเรื่อย ๆ                        | `dsba8-data-warehouse/week01-data-warehouse-setup/lab-week01/`                                                         |
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
mkdir -p dbt_root dbt/lab9/seeds dbt/lab9/snapshots \
  dbt/lab9/models/staging dbt/lab9/models/intermediate dbt/lab9/models/marts \
  dbt/lab9/tests
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01     # เริ่มจาก 0: cd DWH_Lab
New-Item -ItemType Directory -Force dbt_root, dbt/lab9/seeds, dbt/lab9/snapshots, `
  dbt/lab9/models/staging, dbt/lab9/models/intermediate, dbt/lab9/models/marts, `
  dbt/lab9/tests
```

> 💡 Tip: paste as a single line if the line breaks cause errors. คำสั่ง `cd` ด้านบนนับจาก
> root ของรีโป — ถ้าอยู่ที่อื่นให้ใช้ path เต็มแทน

<details>
<summary><b>⚡ คำสั่งลัด — วางไฟล์ SQL/YAML ทั้งหมดของ Lab นี้ในครั้งเดียว</b></summary>

ทุกไฟล์ `.sql` และ `.yml` ของ Lab นี้เตรียมไว้แล้วใน [`script/`](./script/) ถ้าไม่อยากสร้างไฟล์
ทีละไฟล์แล้ว copy-paste จาก README ให้คัดลอกทั้งชุดทีเดียว — วางทั้งสองบรรทัดได้เลย:

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp -r ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/. dbt/lab9/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item -Recurse -Force ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\* dbt\lab9\
```

> ⚠️ คำสั่งนี้แตะเฉพาะ `dbt/lab9/` เท่านั้น — **ไม่รวม `dbt_root/profiles.yml`** ซึ่งใช้ร่วมกัน
> ทุก Lab และต้องเพิ่ม block เองตาม Part 2.3 ส่วน `seeds/*.csv` ที่คัดลอกไว้ก่อนหน้า
> จะไม่ถูกลบ เพราะเป็นการ merge ไม่ใช่ replace

> 📝 ถึงจะใช้คำสั่งลัด ก็ยัง**ควรอ่านคำอธิบายของแต่ละไฟล์ใน Part 3–6** เพราะข้อสอบและ
> Google Form ถามจากเหตุผลเบื้องหลัง ไม่ใช่แค่ผลลัพธ์ที่รันได้

> 💡 **บรรทัด `cd` นับจาก root ของรีโป** ถ้าคุณอยู่ใน `lab-week01/` อยู่แล้ว `cd` จะขึ้น error
> แต่บรรทัด copy ถัดไป**ยังทำงานถูกต้อง** เพราะยืนอยู่ที่เดิมอยู่แล้ว — ข้าม error นี้ได้เลย

> 📝 **คนที่เริ่มจาก 0 และวาง `DWH_Lab/` ไว้นอกรีโป** ให้ `cd` เข้า `DWH_Lab` ของตัวเองแทน
> แล้วชี้ต้นทางด้วย path เต็มไปยัง `week09-etl-incremental-scd-with-dbt/script/dbt/lab9/`

</details>

> ⚠️ **`dbt_root/profiles.yml` เป็นไฟล์ที่ใช้ร่วมกันทุก Lab** — ถ้าคุณทำ Lab 3–8 มาแล้ว ไฟล์นี้
> มี profile ของสัปดาห์ก่อนอยู่ ให้ **เพิ่ม** block `lab9:` ต่อท้าย (Part 2.3) **ห้ามเขียนทับทั้งไฟล์**
> ไม่งั้น Lab เก่าจะรันไม่ได้

> 📝 **ตำแหน่งไฟล์ dataset:** คัดลอก `coffee_sales_scd_new.csv` และ `province_region_mapping_v2.csv`
> ไปไว้ใน `dbt/lab9/seeds/` โดยคงชื่อไฟล์เดิม — ในรีโปนี้อยู่ที่
> [`lab-week09/dbt/lab9/seeds/`](./lab-week09/dbt/lab9/seeds/) ให้แล้ว
>
> **Mac / Linux:**
>
> ```bash
> cp ../../week09-etl-incremental-scd-with-dbt/lab-week09/dbt/lab9/seeds/*.csv dbt/lab9/seeds/
> ```
>
> **Windows (PowerShell):**
>
> ```powershell
> Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\lab-week09\dbt\lab9\seeds\*.csv dbt\lab9\seeds\
> ```

> ⚠️ **ใช้ CSV จากรีโปนี้เท่านั้น** — ไฟล์ต้นฉบับที่แจกมาสะกดจังหวัดชลบุรีว่า `Chon Buri`
> (มีเว้นวรรค) ขณะที่ `province_region_mapping_v2.csv` สะกดว่า `Chonburi` ทำให้ `dim_store`
> ซึ่ง **inner join** กับ `dim_province` **ตกสาขา `ST004` ไปทั้งสาขา** และ `fct_sales`
> จะได้ **30 แถวหลัง Batch 1 / 63 แถวหลัง Batch 2** แทนที่จะเป็น 40 / 80
> ไฟล์ใน [`lab-week09/dbt/lab9/seeds/`](./lab-week09/dbt/lab9/seeds/) แก้เป็น `Chonburi`
> ให้แล้ว (17 แถว) — ถ้าใช้ไฟล์ต้นฉบับ ให้แทนที่ `Chon Buri` → `Chonburi` ทั้งไฟล์ก่อน seed

---

### 2.3 กำหนด profile และ project configuration

`dbt_root/profiles.yml`

> 📝 **นี่คือ block ที่ต้อง _เพิ่ม_ ไม่ใช่ทั้งไฟล์** — ถ้าเคยทำ Lab 3–8 ไฟล์นี้จะมี profile
> ของสัปดาห์ก่อน (`dvd_kpi`, `coffee_dw`, `coffee_dw_snowflake`, `coffee_dw_scd`, `lab7`, `lab8`)
> อยู่แล้ว ให้วาง `lab9:` ต่อท้ายโดยไม่ลบของเดิม (ถ้าเริ่มจาก 0 ไฟล์ยังว่าง — ใส่เฉพาะ block นี้ได้เลย)

```yaml
lab9:
  target: dev
  outputs:
    dev:
      type: postgres
      host: postgres
      user: dw_user
      password: dw_pass
      port: 5432
      dbname: lab9
      schema: dbt
      threads: 4
```

> ⚠️ **ชื่อ host:** dbt ทำงานใน Docker network จึงเชื่อม PostgreSQL ด้วยชื่อ service `postgres`
> และพอร์ตภายใน `5432` — **ไม่ใช้** `localhost` หรือพอร์ต `25432`

`dbt/lab9/dbt_project.yml`

```yaml
name: 'lab9'
version: '1.0.0'
config-version: 2

profile: 'lab9'

model-paths: ['models']
seed-paths: ['seeds']
snapshot-paths: ['snapshots']
test-paths: ['tests']

target-path: 'target'
clean-targets:
  - 'target'
  - 'dbt_packages'

models:
  lab9:
    staging:
      +materialized: view
      +schema: staging
    intermediate:
      +materialized: view
      +schema: intermediate
    marts:
      +schema: marts

snapshots:
  lab9:
    +target_schema: snapshots
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/dbt_project.yml`](./script/dbt/lab9/dbt_project.yml) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/dbt_project.yml dbt/lab9/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\dbt_project.yml dbt\lab9\
```

</details>

> 📝 **ใบ Lab เขียน config แบบบรรทัดเดียว** (`staging: {+materialized: view, +schema: staging}`)
> — ข้างบนกางเป็นแบบหลายบรรทัดเพื่อให้อ่านง่าย ผลลัพธ์เหมือนกันทุกประการ ส่วน
> `test-paths: ['tests']` เพิ่มเข้ามาเพื่อรองรับ singular tests ใน Part 8.2

> 📝 **ชื่อ schema จริงใน PostgreSQL** — dbt ต่อ `+schema` เข้ากับ `schema:` ใน `profiles.yml`
> เป็น `<profile schema>_<+schema>` จึงได้ **`dbt_staging`**, **`dbt_intermediate`** และ
> **`dbt_marts`** ส่วน seed ไม่ได้ตั้ง `+schema` จึงอยู่ที่ **`dbt`** เฉย ๆ
>
> ⚠️ **ยกเว้น snapshot** — `+target_schema` เป็นชื่อ schema แบบ **เต็ม ๆ ไม่เติม prefix**
> ดังนั้น snapshot จะอยู่ที่ schema ชื่อ **`snapshots`** ตรงตัว ไม่ใช่ `dbt_snapshots`

**ตรวจการเชื่อมต่อ**

```bash
docker exec -it dw_dbt bash
cd lab9
dbt debug
```

<details>
<summary><b>Show Output — <code>dbt debug</code></b></summary>

![dbt debug output](./docs/screenshots/dbt-debug.png)

</details>

> ✅ **ผลที่ต้องได้:** `Connection test: OK` และ `All checks passed`

> ⚠️ **ใบ Lab เขียน path ใน container ผิด** — เขียนว่า `cd /usr/app/dbt/lab9` แต่
> `docker-compose.yaml` mount `./dbt:/usr/app` (ไม่ใช่ `./:/usr/app`) ดังนั้นโปรเจกต์อยู่ที่
> **`/usr/app/lab9`** — ใช้ `cd lab9` จาก working dir เริ่มต้นได้เลย

---

## 🌱 Part 3: Load Seeds & Build Staging Models / โหลด Seed และสร้าง Staging Models

> 💡 **คำสั่ง `dbt` ทุกคำสั่งตั้งแต่นี้ไป รันจาก shell ภายใน container** —
> `docker exec -it dw_dbt bash` แล้ว `cd lab9` เพื่อให้เครื่องหมายคำพูดใน `--vars`
> ไม่ถูก shell ของ Windows/macOS แปลงค่าไปก่อน

### 3.1 โหลด CSV ด้วย `dbt seed`

```bash
dbt seed --full-refresh
```

<details>
<summary><b>Show Output — <code>dbt seed --full-refresh</code></b></summary>

![dbt seed output](./docs/screenshots/dbt-seed.png)

</details>

> ✅ **ผลที่คาดหวัง:** `coffee_sales_scd_new` มี **80 แถว** และ `province_region_mapping_v2`
> มี **77 แถว** ทั้งคู่อยู่ใน schema `dbt`

---

### 3.2 ทำความสะอาดข้อมูลยอดขาย

`dbt/lab9/models/staging/stg_coffee_sales.sql`

```sql
with source as (select * from {{ ref('coffee_sales_scd_new') }})
select
  sale_id::bigint as sale_id, invoice_number, sale_date::date as sale_date,
  customer_code, customer_name, gender, birth_year::int as birth_year,
  province, product_code, product_name, category, size,
  unit_price::numeric(12,2) as unit_price, quantity::int as quantity,
  revenue::numeric(18,2) as revenue,
  store_code, store_name, staff_code, staff_name, position,
  nullif(promo_code,'') as promo_code,
  nullif(promo_desc,'') as promo_desc,
  coalesce(points_redeemed,0)::int as points_redeemed
from source
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/staging/stg_coffee_sales.sql`](./script/dbt/lab9/models/staging/stg_coffee_sales.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/staging/stg_coffee_sales.sql dbt/lab9/models/staging/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\staging\stg_coffee_sales.sql dbt\lab9\models\staging\
```

</details>

> 📝 **staging ยังไม่กรอง batch** — view นี้เห็นครบทั้ง **80 แถว** เสมอ การแบ่ง batch เกิดที่
> `int_customer_source` และ `int_sales_batch` ใน Part 5–6 เท่านั้น ดังนั้น **dimensions
> ทุกตัวจึงครบตั้งแต่รอบแรก** และ fact ที่เข้ามาทีหลังจะหา key เจอเสมอ

---

### 3.3 Mapping จังหวัด → ภูมิภาค

`dbt/lab9/models/staging/stg_province_region.sql`

```sql
select province_name, region_name
from {{ ref('province_region_mapping_v2') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/staging/stg_province_region.sql`](./script/dbt/lab9/models/staging/stg_province_region.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/staging/stg_province_region.sql dbt/lab9/models/staging/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\staging\stg_province_region.sql dbt\lab9\models\staging\
```

</details>

---

### 3.4 สร้าง staging layer

```bash
dbt run --select staging
```

> ✅ **ผลที่คาดหวัง:** `stg_coffee_sales` = **80 แถว**, `stg_province_region` = **77 แถว**
> ทั้งคู่เป็น **view** ใน schema `dbt_staging`

---

## ❄️ Part 4: Build the Snowflake Dimensions / สร้าง Snowflake Dimensions

Lab นี้ทำ **Snowflake** ไม่ใช่ Star — มิติถูกแตกเป็นลำดับชั้นต่อกันเป็นทอด ๆ

```text
region ──< province ──< store
category ──< product
position ──< staff
promotion (flat)      date (flat)
```

### 4.1 Geography hierarchy: region → province → store

`dbt/lab9/models/marts/dim_region.sql`

```sql
{{ config(materialized='table') }}
select distinct
  md5(region_name) as region_key,
  region_name
from {{ ref('stg_province_region') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_region.sql`](./script/dbt/lab9/models/marts/dim_region.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_region.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_region.sql dbt\lab9\models\marts\
```

</details>

`dbt/lab9/models/marts/dim_province.sql`

```sql
{{ config(materialized='table') }}
select
  md5(p.province_name) as province_key,
  p.province_name,
  r.region_key
from {{ ref('stg_province_region') }} p
join {{ ref('dim_region') }} r on r.region_name=p.region_name
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_province.sql`](./script/dbt/lab9/models/marts/dim_province.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_province.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_province.sql dbt\lab9\models\marts\
```

</details>

`dbt/lab9/models/marts/dim_store.sql`

```sql
{{ config(materialized='table') }}
select distinct
  md5(s.store_code) as store_key,
  s.store_code, s.store_name, p.province_key
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_province') }} p on p.province_name=s.province
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_store.sql`](./script/dbt/lab9/models/marts/dim_store.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_store.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_store.sql dbt\lab9\models\marts\
```

</details>

> ⚠️ **`dim_store` ใช้ inner join** — สาขาที่จังหวัดสะกดไม่ตรงกับ mapping จะ **หายไปทั้งสาขา**
> และยอดขายของสาขานั้นจะหลุดจาก `fct_sales` ตามไปด้วย (ดู ⚠️ เรื่อง `Chon Buri` ใน Part 2.2)
> Part 8.2 มี singular test ไว้ดักกรณีนี้โดยเฉพาะ

### 4.2 Product hierarchy: category → product

`dbt/lab9/models/marts/dim_category.sql`

```sql
{{ config(materialized='table') }}
select distinct md5(category) as category_key, category as category_name
from {{ ref('stg_coffee_sales') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_category.sql`](./script/dbt/lab9/models/marts/dim_category.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_category.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_category.sql dbt\lab9\models\marts\
```

</details>

`dbt/lab9/models/marts/dim_product.sql`

```sql
{{ config(materialized='table') }}
select distinct
  md5(concat_ws('|',s.product_code,s.size)) as product_key,
  s.product_code, s.product_name, c.category_key, s.size, s.unit_price
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_category') }} c on c.category_name=s.category
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_product.sql`](./script/dbt/lab9/models/marts/dim_product.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_product.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_product.sql dbt\lab9\models\marts\
```

</details>

> 📝 **`product_key` รวม `size` เข้าไปด้วย** — เพราะราคาต่างกันตามขนาด (`PRD-001` S = 55,
> `PRD-002` M = 65) grain ของ `dim_product` จึงเป็น **หนึ่งแถวต่อ (product_code, size)** = 10 แถว

### 4.3 Staff hierarchy: position → staff

`dbt/lab9/models/marts/dim_position.sql`

```sql
{{ config(materialized='table') }}
select distinct md5(position) as position_key, position
from {{ ref('stg_coffee_sales') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_position.sql`](./script/dbt/lab9/models/marts/dim_position.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_position.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_position.sql dbt\lab9\models\marts\
```

</details>

`dbt/lab9/models/marts/dim_staff.sql`

```sql
{{ config(materialized='table') }}
select distinct
  md5(s.staff_code) as staff_key,
  s.staff_code, s.staff_name, p.position_key
from {{ ref('stg_coffee_sales') }} s
join {{ ref('dim_position') }} p on p.position=s.position
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_staff.sql`](./script/dbt/lab9/models/marts/dim_staff.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_staff.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_staff.sql dbt\lab9\models\marts\
```

</details>

### 4.4 Promotion และ Date

`dbt/lab9/models/marts/dim_promotion.sql`

```sql
{{ config(materialized='table') }}
select distinct
  md5(promo_code) as promo_key, promo_code, promo_desc
from {{ ref('stg_coffee_sales') }}
where promo_code is not null
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_promotion.sql`](./script/dbt/lab9/models/marts/dim_promotion.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_promotion.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_promotion.sql dbt\lab9\models\marts\
```

</details>

`dbt/lab9/models/marts/dim_date.sql`

```sql
{{ config(materialized='table') }}
select distinct
  to_char(sale_date,'YYYYMMDD')::int as date_key,
  sale_date,
  extract(year from sale_date)::int as year,
  extract(month from sale_date)::int as month,
  extract(quarter from sale_date)::int as quarter
from {{ ref('stg_coffee_sales') }}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_date.sql`](./script/dbt/lab9/models/marts/dim_date.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_date.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_date.sql dbt\lab9\models\marts\
```

</details>

> 📝 **`dim_date` สร้างจากวันที่ที่มีการขายจริงเท่านั้น** จึงได้ **29 แถว** ไม่ใช่ 30 —
> เดือนเมษายน 2031 มีอยู่หนึ่งวันที่ไม่มีรายการขาย

### 4.5 สร้าง dimensions ทั้งหมด

```bash
dbt run --select dim_region dim_province dim_store dim_category dim_product dim_position dim_staff dim_promotion dim_date
```

> ✅ **ผลที่คาดหวัง** — จำนวนแถวของแต่ละ dimension:
>
> | Model             | Rows | หมายเหตุ                                                                  |
> | ----------------- | ---: | --------------------------------------------------------------------------------- |
> | `dim_region`    |    6 | Central, Northern, Northeastern, Southern, Eastern, Western                       |
> | `dim_province`  |   77 | ครบทั้ง mapping ไม่ใช่เฉพาะจังหวัดที่มียอดขาย |
> | `dim_store`     |    6 | `ST001`–`ST006`                                                              |
> | `dim_category`  |    3 | Coffee, Tea, Chocolate                                                            |
> | `dim_product`   |   10 | หนึ่งแถวต่อ (product_code, size)                                       |
> | `dim_position`  |    2 | Barista, Cashier                                                                  |
> | `dim_staff`     |    6 | `EMP200`–`EMP205`                                                            |
> | `dim_promotion` |    2 | `PRM10` 10% off, `PRM20` 20% off                                              |
> | `dim_date`      |   29 | วันที่ที่มีการขายจริงในเดือน เม.ย. 2031            |

> 📝 **ทำไม `md5()` ถึงสำคัญกับ Lab นี้** — surrogate key ที่มาจาก `md5()` เป็น **deterministic**
> คือ business key เดิมจะได้ค่า key เดิมทุกครั้งที่ rerun ดังนั้นถึง `dim_*` จะถูกสร้างใหม่ทั้งตาราง
> ในรอบ Batch 2 แถวเก่าใน `fct_sales` ที่ถือ key เดิมอยู่ก็ยัง**ชี้ถูกตัว** ไม่กลายเป็น orphan

---

## 🕰️ Part 5: SCD Type 2 ของลูกค้า / Customer SCD Type 2

### 5.1 เลือกสถานะล่าสุดของลูกค้าในแต่ละ batch

`int_customer_source` คือ "ภาพของลูกค้าตามที่ระบบต้นทางส่งมาในรอบนี้" โดยใช้ `sale_date`
ที่เจอชื่อนั้นครั้งแรกเป็น **`source_change_date`** — วันที่ข้อมูลชุดนั้นเริ่มมีผล

`dbt/lab9/models/intermediate/int_customer_source.sql`

```sql
with batch as (
  select *
  from {{ ref('stg_coffee_sales') }}
  {% if var('load_batch','initial') == 'initial' %}
  where sale_date < date '2031-04-15'
  {% else %}
  where sale_date >= date '2031-04-15'
  {% endif %}
), ranked as (
  select
    customer_code, customer_name, gender, birth_year,
    sale_date as source_change_date,
    row_number() over (
      partition by customer_code, customer_name
      order by sale_date, sale_id
    ) as rn
  from batch
)
select customer_code, customer_name, gender, birth_year, source_change_date
from ranked
where rn=1
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/intermediate/int_customer_source.sql`](./script/dbt/lab9/models/intermediate/int_customer_source.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/intermediate/int_customer_source.sql dbt/lab9/models/intermediate/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\intermediate\int_customer_source.sql dbt\lab9\models\intermediate\
```

</details>

> ⚠️ **`partition by customer_code, customer_name` — ไม่ใช่แค่ `customer_code`**
> ใน Batch 2 ลูกค้า `CUST-1007` มีทั้ง `Arthit` (ขาย `2031-04-15`) และ `Tawon` (ขาย `2031-04-30`)
> โมเดลนี้จึงคืน **11 แถวจากลูกค้า 10 คน** — แถว `Arthit` ที่ซ้ำมาจะถูก snapshot มองว่า
> "ไม่มีอะไรเปลี่ยน" แล้วทิ้งไปเอง จึงยังทำงานถูก แต่ถ้าลูกค้าคนเดียวเปลี่ยนชื่อ **สองครั้ง
> ภายใน batch เดียว** ตรรกะนี้จะพัง (จะได้ scd_id ชนกัน) — ในข้อมูลชุดนี้ไม่เกิด

### 5.2 Snapshot: ให้ dbt เปิด/ปิดช่วงเวลาให้เอง

`dbt/lab9/snapshots/snap_customer_scd.sql`

```sql
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
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/snapshots/snap_customer_scd.sql`](./script/dbt/lab9/snapshots/snap_customer_scd.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/snapshots/snap_customer_scd.sql dbt/lab9/snapshots/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\snapshots\snap_customer_scd.sql dbt\lab9\snapshots\
```

</details>

> 📝 **`strategy='check'` เทียบเฉพาะคอลัมน์ใน `check_cols`** — `source_change_date` **ไม่ได้อยู่ใน
> รายการ** จึงไม่ถือเป็นการเปลี่ยนแปลง แถวเดิมจึงยัง**เก็บวันที่เริ่มมีผลของรอบแรกไว้**
> ซึ่งเป็นสิ่งที่เราต้องการ (ไม่งั้น `start_date` ของเวอร์ชันเก่าจะถูกเลื่อนไปเรื่อย ๆ)

dbt จะเติมคอลัมน์ระบบให้เอง:

| คอลัมน์     | ความหมาย                                                                               |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| `dbt_scd_id`     | key ของแต่ละ version                                                                   |
| `dbt_valid_from` | เวลาที่ dbt เห็นเวอร์ชันนี้ครั้งแรก                              |
| `dbt_valid_to`   | เวลาที่เวอร์ชันนี้ถูกปิด (`NULL` = เวอร์ชันปัจจุบัน) |

### 5.3 แปลง snapshot เป็น `dim_customer` ที่ join กับ fact ได้

`dbt/lab9/models/marts/dim_customer.sql`

```sql
{{ config(materialized='table') }}

with versioned as (
  select
    customer_code, customer_name, gender, birth_year,
    source_change_date::date as start_date,
    lead(source_change_date::date) over (
      partition by customer_code
      order by source_change_date::date
    ) as next_start_date,
    dbt_valid_to
  from {{ ref('snap_customer_scd') }}
)
select
  md5(concat_ws('|',customer_code,start_date::text)) as customer_key,
  customer_code, customer_name, gender, birth_year, start_date,
  coalesce(next_start_date - 1,date '9999-12-31') as end_date,
  (dbt_valid_to is null) as is_current
from versioned
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/dim_customer.sql`](./script/dbt/lab9/models/marts/dim_customer.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/dim_customer.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\dim_customer.sql dbt\lab9\models\marts\
```

</details>

> 💡 **ทำไมต้องแปลงอีกชั้น ไม่ใช้ `dbt_valid_from`/`dbt_valid_to` ตรง ๆ?**
> เพราะสองคอลัมน์นั้นเป็น **เวลาที่ dbt รัน** ไม่ใช่ **วันที่ธุรกิจเปลี่ยนจริง** ถ้าเอาไป join
> กับ `sale_date` ยอดขายทั้งเดือนเมษายน 2031 จะตกช่วงหมด — โมเดลนี้จึงคำนวณช่วง
> `start_date`–`end_date` จาก `source_change_date` แทน แล้วปิดท้ายเวอร์ชันล่าสุดด้วย `9999-12-31`

---

## 📈 Part 6: Incremental Fact Model / สร้าง Fact แบบ Incremental

### 6.1 จำกัดขอบเขตข้อมูลของ batch

`dbt/lab9/models/intermediate/int_sales_batch.sql`

```sql
select *
from {{ ref('stg_coffee_sales') }}
{% if var('load_batch','initial') == 'initial' %}
where sale_date < date '2031-04-15'
{% else %}
where sale_date >= date '2031-04-15'
{% endif %}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/intermediate/int_sales_batch.sql`](./script/dbt/lab9/models/intermediate/int_sales_batch.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/intermediate/int_sales_batch.sql dbt/lab9/models/intermediate/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\intermediate\int_sales_batch.sql dbt\lab9\models\intermediate\
```

</details>

### 6.2 Fact table

`dbt/lab9/models/marts/fct_sales.sql`

```sql
{{
  config(
    materialized='incremental',
    unique_key='sale_id',
    incremental_strategy='merge'
  )
}}
select
  s.sale_id, s.invoice_number, d.date_key, c.customer_key,
  p.product_key, st.store_key, sf.staff_key, pr.promo_key,
  s.quantity, s.revenue, s.points_redeemed
from {{ ref('int_sales_batch') }} s
join {{ ref('dim_date') }} d on d.sale_date=s.sale_date
join {{ ref('dim_customer') }} c
  on c.customer_code=s.customer_code
 and s.sale_date between c.start_date and c.end_date
join {{ ref('dim_product') }} p on p.product_code=s.product_code and p.size=s.size
join {{ ref('dim_store') }} st on st.store_code=s.store_code
join {{ ref('dim_staff') }} sf on sf.staff_code=s.staff_code
left join {{ ref('dim_promotion') }} pr on pr.promo_code=s.promo_code
{% if is_incremental() %}
where not exists (
  select 1 from {{ this }} f where f.sale_id=s.sale_id
)
{% endif %}
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/marts/fct_sales.sql`](./script/dbt/lab9/models/marts/fct_sales.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/marts/fct_sales.sql dbt/lab9/models/marts/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\marts\fct_sales.sql dbt\lab9\models\marts\
```

</details>

**สามบรรทัดที่ทำให้ Lab นี้เป็น Incremental + SCD 2:**

| บรรทัด                                        | ทำอะไร                                                                                                                              |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `materialized='incremental'`                      | รอบแรกสร้างตารางใหม่ รอบถัดไป**ต่อท้าย** ไม่ drop ของเดิม                              |
| `s.sale_date between c.start_date and c.end_date` | ผูกยอดขายกับ**เวอร์ชันลูกค้าที่มีผลในวันขาย** ไม่ใช่ชื่อล่าสุดเสมอไป |
| `where not exists (... from {{ this }} ...)`      | กันแถวซ้ำอีกชั้น นอกเหนือจาก`unique_key` + `merge`                                                         |

> 💡 **`{{ this }}` คือตัวตารางเองที่มีอยู่แล้วใน database** — บล็อกนี้ทำงานเฉพาะรอบที่
> `is_incremental()` เป็นจริง คือ **รอบที่ 2 เป็นต้นไป** (ตารางมีอยู่แล้วและไม่ได้สั่ง `--full-refresh`)

> ⚠️ **`left join dim_promotion`** — ข้อมูล 33 จาก 80 แถวไม่มีโปรโมชัน ถ้าเปลี่ยนเป็น inner join
> แถวเหล่านั้นจะหายไปทันที และ `fct_sales` จะไม่ได้ 40 / 80 ตามที่ใบ Lab คาดไว้

---

## 🚚 Part 7: Run the Two Batches / โหลดจริงทั้งสองรอบ

> 💡 รันทุกคำสั่งด้านล่างจาก shell ภายใน container: `docker exec -it dw_dbt bash` แล้ว `cd lab9`
> เพื่อให้ `--vars` ถูกส่งเป็น JSON ตรง ๆ ไม่โดน shell ของ Windows/macOS แปลงเครื่องหมายคำพูด

> ⚠️ **ลำดับสำคัญมาก** — ต้อง `int_customer_source` → `snapshot` → `dim_customer` + fact เสมอ
> เพราะ snapshot อ่านจาก `int_customer_source` และ `dim_customer` อ่านจาก snapshot

### 7.1 Batch 1 — Initial Load

```bash
dbt run --select int_customer_source --vars "{'load_batch': 'initial'}"
dbt snapshot --select snap_customer_scd --vars "{'load_batch': 'initial'}"
dbt run --select dim_customer int_sales_batch fct_sales --vars "{'load_batch': 'initial'}"
```

<details>
<summary><b>Show Output — Batch 1</b></summary>

![dbt run batch 1](./docs/screenshots/dbt-batch1.png)

</details>

### 7.2 ตรวจผลหลัง Batch 1

```bash
dbt show --inline "select count(*) as fact_rows from {{ ref('fct_sales') }}"
dbt show --inline "select count(*) as customer_rows from {{ ref('dim_customer') }}"
```

หรือใน pgAdmin Query Tool:

```sql
select count(*) as fact_rows from dbt_marts.fct_sales;
select count(*) as customer_rows from dbt_marts.dim_customer;
select * from snapshots.snap_customer_scd where customer_code = 'CUST-1007';
```

> ✅ **ผลที่คาดหวังหลัง Batch 1**
>
> | รายการ                 | ค่า                                                |
> | ---------------------------- | ----------------------------------------------------- |
> | `fct_sales`                | **40 แถว**                                   |
> | `int_sales_batch`          | 40 แถว (`2031-04-01` → `2031-04-14`)          |
> | `snap_customer_scd`        | 10 แถว — ทุกคนมีเวอร์ชันเดียว |
> | `dim_customer`             | 10 แถว —`is_current = true` ทั้งหมด      |
> | `CUST-1007`                | ชื่อ`Arthit` เท่านั้น                   |
> | `sum(revenue)` ของ fact | 5,175.00                                              |

### 7.3 Batch 2 — Incremental Load

```bash
dbt run --select int_customer_source --vars "{'load_batch': 'incremental'}"
dbt snapshot --select snap_customer_scd --vars "{'load_batch': 'incremental'}"
dbt run --select dim_customer int_sales_batch fct_sales --vars "{'load_batch': 'incremental'}"
```

<details>
<summary><b>Show Output — Batch 2</b></summary>

![dbt run batch 2](./docs/screenshots/dbt-batch2.png)

</details>

> ⚠️ **ห้ามใช้ `dbt build` หรือ `dbt snapshot` เปล่า ๆ หลังโหลด Batch 2**
> ทั้งสองคำสั่งจะรัน snapshot ด้วยค่า default `load_batch='initial'` ซึ่งทำให้ dbt เห็นชื่อ
> `Arthit` เป็น "ค่าใหม่" แล้ว **ปิดเวอร์ชัน `Tawon` และเปิด `Arthit` ซ้ำอีกรอบ** — ประวัติ SCD จะเพี้ยน
> ถ้าเผลอรันไปแล้ว ให้เริ่มใหม่ด้วย `dbt run --select int_customer_source --vars "{'load_batch': 'initial'}"`,
> `dbt snapshot --select snap_customer_scd --full-refresh --vars "{'load_batch': 'initial'}"`
> แล้วไล่ทำ Part 7.1 → 7.3 ใหม่ทั้งหมด

### 7.4 ตรวจผลหลัง Batch 2 และดูประวัติ SCD

```sql
select count(*) as fact_rows from dbt_marts.fct_sales;

select sale_id, count(*)
from dbt_marts.fct_sales
group by sale_id
having count(*) > 1;          -- ต้องไม่มีแถวเลย

select customer_code, customer_name, start_date, end_date, is_current
from dbt_marts.dim_customer
where customer_code = 'CUST-1007'
order by start_date;
```

<details>
<summary><b>📷 SCD history ของ <code>CUST-1007</code></b></summary>

![SCD Type 2 history for CUST-1007](./docs/screenshots/scd-cust-1007.png)

</details>

> ✅ **ผลที่คาดหวังหลัง Batch 2**
>
> | รายการ                 | ค่า                                                        |
> | ---------------------------- | ------------------------------------------------------------- |
> | `fct_sales`                | **80 แถว** และ `sale_id` **ไม่ซ้ำ** |
> | `snap_customer_scd`        | 11 แถว                                                     |
> | `dim_customer`             | 11 แถว                                                     |
> | `sum(revenue)` ของ fact | 9,535.50 (Batch 1 5,175.00 + Batch 2 4,360.50)                |
>
> **ประวัติของ `CUST-1007` ต้องได้ 2 เวอร์ชัน:**
>
> | customer_name | start_date     | end_date       | is_current |
> | ------------- | -------------- | -------------- | ---------- |
> | `Arthit`    | `2031-04-03` | `2031-04-29` | `false`  |
> | `Tawon`     | `2031-04-30` | `9999-12-31` | `true`   |

> 💡 **ยอดขายเก่ายังเป็นของ `Arthit`** — `CUST-1007` มีรายการขายวันที่ `2031-04-15` ซึ่งอยู่ใน
> Batch 2 แต่ **ยังตกในช่วงของเวอร์ชัน `Arthit`** (ชื่อเพิ่งเปลี่ยนวันที่ `2031-04-30`)
> แถวนั้นจึงถูกผูกกับ `Arthit` อย่างถูกต้อง — นี่คือสิ่งที่ SCD Type 2 ให้ แต่ Type 1 ให้ไม่ได้

---

## ✅ Part 8: Tests, `dbt show` & `dbt docs` / ตรวจสอบผลลัพธ์

> 📝 **ส่วนนี้ใบ Lab ระบุไว้ในวัตถุประสงค์ข้อ 5 แต่ไม่มีขั้นตอนให้** — README เติมให้ครบ
> โดยใช้กติกาที่ตรงกับผลลัพธ์ที่ Part 7 คาดไว้

### 8.1 Generic tests และ documentation

`dbt/lab9/models/schema.yml`

```yaml
version: 2

models:
  - name: stg_coffee_sales
    description: "ยอดขายที่ cast type แล้ว — 1 แถวต่อ 1 sale_id (80 แถว)"
    columns:
      - name: sale_id
        description: "Business key ของรายการขาย"
        tests: [unique, not_null]
      - name: sale_date
        tests: [not_null]

  - name: stg_province_region
    description: "Mapping จังหวัด → ภูมิภาค (77 แถว)"
    columns:
      - name: province_name
        tests: [unique, not_null]

  - name: dim_region
    description: "ระดับบนสุดของ geography hierarchy (6 แถว)"
    columns:
      - name: region_key
        tests: [unique, not_null]

  - name: dim_province
    description: "ระดับกลางของ geography hierarchy (77 แถว)"
    columns:
      - name: province_key
        tests: [unique, not_null]
      - name: region_key
        tests:
          - relationships:
              to: ref('dim_region')
              field: region_key

  - name: dim_store
    description: "ระดับล่างสุดของ geography hierarchy (6 สาขา)"
    columns:
      - name: store_key
        tests: [unique, not_null]
      - name: province_key
        tests:
          - relationships:
              to: ref('dim_province')
              field: province_key

  - name: dim_category
    columns:
      - name: category_key
        tests: [unique, not_null]

  - name: dim_product
    description: "grain = หนึ่งแถวต่อ (product_code, size)"
    columns:
      - name: product_key
        tests: [unique, not_null]
      - name: category_key
        tests:
          - relationships:
              to: ref('dim_category')
              field: category_key

  - name: dim_position
    columns:
      - name: position_key
        tests: [unique, not_null]

  - name: dim_staff
    columns:
      - name: staff_key
        tests: [unique, not_null]
      - name: position_key
        tests:
          - relationships:
              to: ref('dim_position')
              field: position_key

  - name: dim_promotion
    columns:
      - name: promo_key
        tests: [unique, not_null]

  - name: dim_date
    columns:
      - name: date_key
        tests: [unique, not_null]

  - name: dim_customer
    description: "SCD Type 2 — หนึ่งแถวต่อหนึ่งเวอร์ชันของลูกค้า"
    columns:
      - name: customer_key
        tests: [unique, not_null]
      - name: customer_code
        tests: [not_null]
      - name: is_current
        tests: [not_null]

  - name: fct_sales
    description: "Fact แบบ incremental — grain = หนึ่งแถวต่อ sale_id"
    columns:
      - name: sale_id
        tests: [unique, not_null]
      - name: revenue
        tests: [not_null]
      - name: date_key
        tests:
          - relationships:
              to: ref('dim_date')
              field: date_key
      - name: customer_key
        tests:
          - relationships:
              to: ref('dim_customer')
              field: customer_key
      - name: product_key
        tests:
          - relationships:
              to: ref('dim_product')
              field: product_key
      - name: store_key
        tests:
          - relationships:
              to: ref('dim_store')
              field: store_key
      - name: staff_key
        tests:
          - relationships:
              to: ref('dim_staff')
              field: staff_key
      - name: promo_key
        tests:
          - relationships:
              to: ref('dim_promotion')
              field: promo_key
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/models/schema.yml`](./script/dbt/lab9/models/schema.yml) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/models/schema.yml dbt/lab9/models/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\models\schema.yml dbt\lab9\models\
```

</details>

> 📝 **`promo_key` ไม่ต้องใส่ `not_null`** — มาจาก `left join` จึงเป็น `NULL` ได้ 33 แถว
> ส่วน test `relationships` ของ dbt ข้ามค่า `NULL` ให้อยู่แล้ว

### 8.2 Singular tests สำหรับกฎเฉพาะของ Lab นี้

`dbt/lab9/tests/assert_fct_sales_unique_sale_id.sql`

```sql
-- Incremental Load ต้องไม่ทำให้เกิด sale_id ซ้ำหลังโหลด Batch 2
select
    sale_id,
    count(*) as row_count
from {{ ref('fct_sales') }}
group by sale_id
having count(*) > 1
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/tests/assert_fct_sales_unique_sale_id.sql`](./script/dbt/lab9/tests/assert_fct_sales_unique_sale_id.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/tests/assert_fct_sales_unique_sale_id.sql dbt/lab9/tests/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\tests\assert_fct_sales_unique_sale_id.sql dbt\lab9\tests\
```

</details>

`dbt/lab9/tests/assert_customer_one_current_version.sql`

```sql
-- SCD Type 2: ลูกค้าหนึ่งคนต้องมีเวอร์ชันปัจจุบันเพียงหนึ่งเดียว
select
    customer_code,
    count(*) as current_versions
from {{ ref('dim_customer') }}
where is_current
group by customer_code
having count(*) <> 1
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/tests/assert_customer_one_current_version.sql`](./script/dbt/lab9/tests/assert_customer_one_current_version.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/tests/assert_customer_one_current_version.sql dbt/lab9/tests/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\tests\assert_customer_one_current_version.sql dbt\lab9\tests\
```

</details>

`dbt/lab9/tests/assert_all_sale_provinces_mapped.sql`

```sql
-- ทุกจังหวัดในข้อมูลขายต้องหาเจอใน mapping ไม่งั้น dim_store จะตกสาขา
select distinct
    s.province
from {{ ref('stg_coffee_sales') }} s
left join {{ ref('stg_province_region') }} p
       on p.province_name = s.province
where p.province_name is null
```

<details>
<summary><b>⚡ คำสั่งลัด — คัดลอกไฟล์นี้แทนการสร้างเอง</b></summary>

ต้นทาง: [`script/dbt/lab9/tests/assert_all_sale_provinces_mapped.sql`](./script/dbt/lab9/tests/assert_all_sale_provinces_mapped.sql) — วางทั้งสองบรรทัดได้เลย โดย `cd` นับจาก **root ของรีโป**

**Mac / Linux:**

```bash
cd week01-data-warehouse-setup/lab-week01
cp ../../week09-etl-incremental-scd-with-dbt/script/dbt/lab9/tests/assert_all_sale_provinces_mapped.sql dbt/lab9/tests/
```

**Windows (PowerShell):**

```powershell
cd week01-data-warehouse-setup\lab-week01
Copy-Item ..\..\week09-etl-incremental-scd-with-dbt\script\dbt\lab9\tests\assert_all_sale_provinces_mapped.sql dbt\lab9\tests\
```

</details>

### 8.3 รัน tests และ preview ด้วย `dbt show`

```bash
dbt test
```

<details>
<summary><b>Show Output — <code>dbt test</code></b></summary>

![dbt test output](./docs/screenshots/dbt-test.png)

</details>

> ⚠️ **ใช้ `dbt test` ไม่ใช่ `dbt build`** — `dbt build` จะรัน snapshot ซ้ำด้วยค่า default
> `load_batch='initial'` แล้วทำให้ประวัติ SCD เพี้ยนตามที่เตือนไว้ใน Part 7.3

Preview ผลลัพธ์แบบเร็ว ๆ:

```bash
dbt show --select fct_sales --limit 10
dbt show --select dim_customer --limit 15
dbt show --inline "select customer_name, start_date, end_date, is_current from {{ ref('dim_customer') }} where customer_code='CUST-1007' order by start_date"
```

### 8.4 สร้างเอกสารและดู Lineage

```bash
dbt docs generate
dbt docs serve --host 0.0.0.0 --port 8080
```

เปิดเบราว์เซอร์ที่ [http://localhost:28088](http://localhost:28088) (พอร์ต `8080` ใน container
ถูก map ออกมาเป็น `28088` ใน `docker-compose.yaml`) แล้วกดปุ่ม **View Lineage Graph** มุมขวาล่าง

<details>
<summary><b>📷 dbt docs — Lineage graph</b></summary>

![dbt docs lineage graph](./docs/screenshots/dbt-docs-lineage.png)

</details>

> ✅ **Lineage ที่ควรเห็น:**
>
> ```text
> coffee_sales_scd_new ─┬─ stg_coffee_sales ─┬─ int_customer_source ─ snap_customer_scd ─ dim_customer ─┐
>                       │                    ├─ int_sales_batch ─────────────────────────────────────── fct_sales
>                       │                    └─ dim_store / dim_product / dim_staff / dim_promotion / dim_date ─┘
> province_region_mapping_v2 ─ stg_province_region ─ dim_region ─ dim_province ─ dim_store
> ```

---

## 📤 Submission / สิ่งที่ต้องส่ง

ส่งคำตอบผ่าน **Google Form — Lab 9: ETL Incremental Load & SCD Type 2** *(ลิงก์จากผู้สอน)*

| รายการ           | รูปแบบ                                                                                                          |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Checkpoint 1** | Screenshot จำนวนแถวของ`fct_sales` **หลัง Batch 1 = 40** และ **หลัง Batch 2 = 80** |
| **Checkpoint 2** | Screenshot**SCD history ของ `CUST-1007`** ที่เห็นทั้ง `Arthit` และ `Tawon`               |

> 📝 Screenshot ของ Checkpoint 2 ควรเห็นครบทั้ง `customer_name`, `start_date`, `end_date`
> และ `is_current` ทั้งสองแถว เพื่อพิสูจน์ว่าเวอร์ชันเก่า **ถูกปิด** ไม่ใช่ **ถูกทับ**

---

## 🛠️ dbt Cheat Sheet

> ⚠️ เปิด shell ใน container ก่อน — `docker exec -it dw_dbt bash` แล้ว `cd lab9`
> เพื่อไม่ให้เครื่องหมายคำพูดใน `--vars` และ Jinja ใน `--inline` ถูก host shell แปลงค่า

| Command                                                             | Description                                                 |
| ------------------------------------------------------------------- | ----------------------------------------------------------- |
| `docker exec -it dw_dbt bash`                                     | Open a shell inside the dbt container                       |
| `dbt debug`                                                       | Test the database connection                                |
| `dbt seed --full-refresh`                                         | Rebuild both seed tables from the CSVs                      |
| `dbt run --select staging`                                        | Build the two staging views                                 |
| `dbt run --select dim_region dim_province dim_store ...`          | Build the Snowflake dimensions                              |
| `dbt run --select <model> --vars "{'load_batch': 'initial'}"`     | Run a model scoped to**Batch 1**                      |
| `dbt run --select <model> --vars "{'load_batch': 'incremental'}"` | Run a model scoped to**Batch 2**                      |
| `dbt snapshot --select snap_customer_scd --vars "{...}"`          | Advance the SCD Type 2 history                              |
| `dbt run --select fct_sales --full-refresh --vars "{...}"`        | **Rebuild** the fact from scratch (drops loaded rows) |
| `dbt test`                                                        | Run generic + singular tests                                |
| `dbt test --select fct_sales`                                     | Run only the fact table's tests                             |
| `dbt show --select <model> --limit 10`                            | Preview a model's rows                                      |
| `dbt show --inline "select ... from {{ ref('<model>') }}"`        | Preview an ad-hoc query                                     |
| `dbt ls --resource-type model`                                    | List every model in the project                             |
| `dbt docs generate`                                               | Build the documentation site                                |
| `dbt docs serve --host 0.0.0.0 --port 8080`                       | Serve the docs (browser:`localhost:28088`)                |

---

## 🧾 Incremental & SCD Quick Reference

| แนวคิด                         | ทำอะไร                                                                         | ในโปรเจกต์นี้                                      |
| ------------------------------------ | ------------------------------------------------------------------------------------ | --------------------------------------------------------------- |
| **Full refresh**               | สร้างใหม่ทั้งตารางทุกครั้ง                                 | seeds, staging, dimensions ทั่วไป                         |
| **Incremental**                | ต่อท้ายเฉพาะแถวใหม่ ไม่แตะของเก่า                    | `fct_sales`                                                   |
| **`unique_key` + `merge`** | ถ้าเจอ key เดิม → update แทน insert ซ้ำ                             | `unique_key='sale_id'`                                        |
| **`is_incremental()`**       | จริงเมื่อ "ตารางมีอยู่แล้ว + ไม่ได้`--full-refresh`" | บล็อก`where not exists` ใน `fct_sales`               |
| **Snapshot (`check`)**       | dbt เทียบ`check_cols` แล้วเปิด/ปิดเวอร์ชันให้เอง     | `snap_customer_scd`                                           |
| **SCD Type 2**                 | เก็บทุกเวอร์ชันพร้อมช่วงเวลาที่มีผล               | `dim_customer` (`start_date`, `end_date`, `is_current`) |
| **`--vars`**                 | ส่งค่าจาก CLI เข้า Jinja เพื่อสลับขอบเขตข้อมูล     | `load_batch` = `initial` / `incremental`                  |

| SCD Type | เกิดอะไรเมื่อค่าเปลี่ยน          | ตอบคำถาม "ตอนนั้นชื่ออะไร" ได้ไหม |
| :------: | ------------------------------------------------------- | :------------------------------------------------------------: |
|  Type 0  | ไม่ให้เปลี่ยน                              |                               —                               |
|  Type 1  | เขียนทับค่าเดิม                          |                          ไม่ได้                          |
|  Type 2  | **เพิ่มแถวใหม่ ปิดแถวเก่า** |                        **ได้**                        |
|  Type 3  | เก็บค่าก่อนหน้าไว้ 1 คอลัมน์   |               ได้แค่ค่าก่อนหน้า               |

---

*Data Warehouse — DSBA8 | Week 9*

# 📦 Week 3: Requirement Gathering & KPI Layer

> **Course:** Data Warehousing (การสร้างคลังข้อมูล)  
> **Topic:** Requirement Gathering, Business Process, KPI Layer with dbt & Metabase  
> **Duration:** 2 Hours

---

## 🎯 Learning Objectives / วัตถุประสงค์

1. Understand **Requirement Gathering** for Data Warehousing.
2. Translate Business Processes into measurable **KPIs**.
3. Understand Grain and build **Fact Models** using dbt.
4. Create a **Metric Catalog** and **Metric Models** using dbt.
5. Build an interactive **KPI Dashboard** in Metabase using the calculated metrics.

---

## 🧰 Tools & Stack Overview / เครื่องมือที่ใช้

| Tool | What is it? | What is it used for in this lab? |
|---|---|---|
| **dbt (data build tool)** | Data Transformation Tool | Building Fact Models and Metric Models |
| **PostgreSQL 16** | Relational Database (RDBMS) | Data warehouse storage for dbt outputs |
| **Metabase** | Open-source BI & Visualization Tool | Building the KPI Dashboard |

---

## 📁 Files in This Week / ไฟล์ในสัปดาห์นี้

| File / Folder | Description |
|---|---|
| 📂 [slides/](./slides/) | Lecture slides |
| └── 📄 [3 - Requirement Gathering for DW.pdf](./slides/3%20-%20Requirement%20Gathering%20for%20DW.pdf) | Lecture: Requirement Gathering for DW |
| 📂 [docs/](./docs/) | Lab instructions |
| ├── 📄 [Lab3 KPI Layer.pdf](./docs/Lab3%20KPI%20Layer.pdf) | Lab instruction (PDF) |
| └── 📝 [Lab3 KPI Layer.docx](./docs/Lab3%20KPI%20Layer.docx) | Lab instruction (Word) |
| 📂 [lab-week03/](./lab-week03/) | Lab files |
| └── *(Student working directory for dbt)* | |

---

## 🔧 Part 1: Requirement to KPIs

In this lab, we build upon the `dvdrental` database. We will translate business requirements into 5 key metrics (KPIs):
- **M001:** Total Revenue (ยอดขายรวม)
- **M002:** Total Rental Count (จำนวนการเช่าทั้งหมด)
- **M003:** Active Customer Count (จำนวนลูกค้าที่มาใช้บริการ)
- **M004:** Average Revenue Per User - ARPU (รายได้เฉลี่ยต่อลูกค้า)
- **M005:** Late Return Rate (อัตราส่วนการคืนหนังล่าช้า)

---

## 🏗️ Part 2: Building with dbt & Running Tests

We will use **dbt** to define the Business Logic in one central place. 

### Step 1 — Build all Models and run Tests
Run the following command to build the dbt project. Since we are using Docker, you need to execute this inside the `dw_dbt` container:

**Mac / Linux:**
```bash
docker exec -it dw_dbt dbt build
```

**Windows (PowerShell):**
```powershell
docker exec -it dw_dbt dbt build
```
*(This automatically runs seeds, staging, intermediate, fact models, metric models, and tests!)*

### Step 2 — Verify Metric Catalog
Run this SQL in Metabase (SQL Editor) or pgAdmin to check if the Metric Catalog is built correctly:
```sql
SELECT *
FROM dbt_metadata.metric_definition
ORDER BY metric_key;
```

### Step 3 — Verify Company-Level KPIs
```sql
SELECT
    metric_month,
    metric_key,
    metric_label,
    metric_value,
    unit
FROM dbt_metrics.metric_company_monthly
ORDER BY metric_month, metric_key
LIMIT 20;
```

### Step 4 — Verify Store-Level KPIs
```sql
SELECT
    metric_month,
    store_id,
    metric_key,
    metric_label,
    metric_value
FROM dbt_metrics.metric_store_monthly
ORDER BY metric_month, store_id, metric_key
LIMIT 30;
```
> 💡 **Checkpoint:** In one month, `metric_company_monthly` should have no more than 5 rows (M001-M005) and `metric_store_monthly` should have no more than 5 rows per store. If you see more, check your `GROUP BY` and `JOIN` logic!

---

## 📊 Part 3: Visualizing in Metabase

### Step 1 — Connect Database & Sync Schema
1. Open Metabase at `http://localhost:23000`
2. Go to **Admin settings** → **Databases** → **dvdrental** and click **Sync database schema now**.
3. Verify Metabase can see `dbt_metrics` and `dbt_metadata` schemas (If not, wait a moment and refresh).

### Step 2 — Create Question: KPI Trend by Metric Key
1. Select **New → Question** → dvdrental → dbt_metrics → `metric_company_monthly`
2. Add a Filter: `metric_key = 'M001'`
3. Select Visualization: **Line Chart**
4. X-axis = `metric_month`, Y-axis = `metric_value`
5. Save as **KPI Trend by Metric Key**

### Step 3 — Create Question: KPI by Store
1. Select table `dbt_metrics.metric_store_monthly`
2. Add a Filter: `metric_key = 'M001'`
3. Select Visualization: **Bar Chart**
4. X-axis = `store_id`, Y-axis = `metric_value`
5. Save as **KPI by Store**

### Step 4 — Create Question: Late Return Rate by Store
1. Duplicate the "KPI by Store" question
2. Change Filter to: `metric_key = 'M005'`
3. In Formatting, set `metric_value` as **Percent**
4. Save as **Late Return Rate by Store**

### Step 5 — Create Question: Metric Catalog
1. Select table `dbt_metadata.metric_definition`
2. Show columns: `metric_key`, `metric_label`, `description`, `formula`, `unit`
3. Select Visualization: **Table**
4. Save as **Metric Catalog**

### Step 6 — Assemble the Dashboard
1. Create a Dashboard named **DVD Rental KPI Dashboard - [Student ID]**
2. Add all 4 Questions to the Dashboard
3. Add a **Dropdown Filter** named `Metric Key` and connect it to `metric_key` of "KPI Trend" and "KPI by Store"
4. Add a **Date Filter** and connect it to `metric_month`
5. Arrange the layout so it is clear and easy to read!

> ⚠️ **Caution:** Different Metric Keys have different units (currency, count, ratio). Changing `metric_key` in the same chart might not change the Y-axis format automatically. 

---

## 📝 Assignment / สิ่งที่ต้องส่ง

**1. Screenshot Dashboard:** Submit a screenshot of your Metabase Dashboard (PNG / JPG).

**2. Analysis Questions:** Answer these 4 questions in the Google Form:
1. เพราะเหตุใดจึงต้อง Aggregate payment ให้เหลือหนึ่งแถวต่อ rental_id ก่อน Join กับ rental?
2. เพราะเหตุใด Active Customer Count รายปีจึงไม่ควรคำนวณด้วยการบวก Active Customer Count ของแต่ละเดือน?
3. ถ้าเปลี่ยนนิยาม Late Return เป็น “คืนเกินกำหนดอย่างน้อย 2 วัน” ต้องแก้ไขไฟล์ใด และต้องรันคำสั่งใดอีกครั้ง?
4. หากให้ผู้ใช้เขียนสูตร M004 และ M005 เองทุก Dashboard จะเกิดความเสี่ยงอย่างไร?

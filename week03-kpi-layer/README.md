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

## 🏗️ Part 2: Building with dbt

We will use **dbt** to define the Business Logic in one central place:
1. **Fact Models:** Aggregate data to the correct grain (e.g., `rental_id`).
2. **Metric Catalog:** Create definitions for the 5 KPIs.
3. **Metric Models:** Calculate the KPIs at the Company Level (`metric_company_monthly`) and Store Level (`metric_store_monthly`).

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

---

## 📊 Part 3: Visualizing in Metabase

1. Open Metabase at `http://localhost:23000`
2. Sync the database schema to ensure Metabase sees `dbt_metrics` and `dbt_metadata`.
3. Create Questions utilizing the Metric Models:
   - **KPI Trend by Metric Key** (Line Chart)
   - **KPI by Store** (Bar Chart)
   - **Late Return Rate by Store**
   - **Metric Catalog** (Table)
4. Assemble them into the **DVD Rental KPI Dashboard** with Metric Key and Date Filters.

> 💡 **Core Concept:** By using dbt as the central source of truth for business logic, you don't need to write complex `SUM`, `COUNT DISTINCT`, or division formulas in Metabase. If a KPI definition changes, you only update it once in dbt, and all Metabase dashboards update automatically!

---

## 📝 Assignment

1. Submit a **Screenshot of your Metabase Dashboard** (PNG / JPG).
2. Answer the 4 analysis questions in the provided Google Form.

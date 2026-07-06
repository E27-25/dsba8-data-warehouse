# 📦 Week 1: Data Warehouse Setup & Exploration

> **Course:** Data Warehousing (การสร้างคลังข้อมูล)  
> **Topic:** Environment Setup with Docker & Basic Data Exploration  
> **Duration:** 2 Hours

---

## 🎯 Learning Objectives / วัตถุประสงค์
1. Set up the development environment stack using **Docker Compose**.
2. Create a database, table, and import data via **pgAdmin**.
3. Connect the PostgreSQL database to **Metabase** and perform basic data exploration/visualization.
4. Build a foundation for future Data Warehouse labs (dbt, Airflow, etc.).

---

## 🧰 Tools & Stack Overview / เครื่องมือที่ใช้

| Tool | What is it? | What is it used for in this lab? |
|---|---|---|
| **Docker** | Containerization Platform | Runs PostgreSQL, pgAdmin, Airflow, dbt, and Metabase in isolated environments without local installation. |
| **PostgreSQL 16** | Relational Database (RDBMS) | Stores our structured transactional and analytical data. |
| **pgAdmin 4** | Database GUI Management Tool | Used to interact with PostgreSQL, run SQL queries, and import CSV datasets. |
| **Metabase** | Open-source BI & Visualization Tool | Connects to PostgreSQL to create charts and dashboards. |
| **dbt** / **Airflow** | Transformation / Ingestion | (Setup for future weeks - running in background). |

---

## 📁 Files in This Week / ไฟล์ในสัปดาห์นี้

| File / Folder | Description |
|---|---|
| 📂 [docs/](./docs/) | Contains lab instructions and assignments. |
| ├── 📄 [Lab1 Data Warehouse Setup.docx](./docs/Lab1%20Data%20Warehouse%20Setup.docx) | Lab instruction document (Word). |
| └── 📄 [Lab1 Data Warehouse Setup.pdf](./docs/Lab1%20Data%20Warehouse%20Setup.pdf) | Lab instruction document (PDF). |
| 📂 [slides/](./slides/) | Contains weekly lecture slides. |
| ├── 📄 [1 - Introduction to Data Warehouse.pdf](./slides/1%20-%20Introduction%20to%20Data%20Warehouse.pdf) | Lecture slides: Introduction to Data Warehousing. |
| └── 📄 [Overview.pdf](./slides/Overview.pdf) | Lecture slides: Course Overview. |
| 📂 [data/](./data/) | Contains dataset files for the lab. |
| └── 📊 [Sample - Superstore.csv](./data/Sample%20-%20Superstore.csv) | Superstore transaction dataset. |
| 📂 [lab-week01/](./lab-week01/) | Contains environment setup files. |
| ├── 🐳 [docker-compose.yaml](./lab-week01/docker-compose.yaml) | Full stack definition (PostgreSQL, Airflow, dbt, Metabase, pgAdmin). |
| ├── 🐳 [dockerfile.airflow](./lab-week01/dockerfile.airflow) | Custom Airflow image with `git`, `dbt-core`, and `dbt-postgres` installed. |
| ├── ⚙️ [postgresql.conf](./lab-week01/postgresql.conf) | Custom PostgreSQL configuration. |
| └── 📦 [DWH_Lab.zip](./lab-week01/DWH_Lab.zip) | Complete lab archive. |

---

## 🔧 Part 1: Environment Setup / การติดตั้งระบบจำลอง

### 1. Check System Specifications
Ensure your machine meets the recommended specs for running the stack:
* **RAM:** $\ge$ 16 GB (Recommended)
* **Disk Space:** $\ge$ 30 GB free
* **Docker Desktop:** Installed and running. Download from [Docker Desktop](https://www.docker.com/products/docker-desktop).

> 🍎 **Mac (Apple Silicon / M1–M4) users:** The `docker-compose.yaml` already includes `platform: linux/amd64` for all services. Docker will run the x86 images via Rosetta 2 emulation automatically — no extra steps needed.

### 2. Verify Docker Installation
Open your terminal (macOS/Linux) or PowerShell (Windows) and run:
```bash
docker --version
docker compose version
```

### 3. Start the Lab Environment
1. Extract the `DWH_Lab.zip` file (Ensure there are no Thai characters in the folder path).
2. Open your terminal/PowerShell, navigate to the `lab-week01` folder:
   ```bash
   cd week01-data-warehouse-setup/lab-week01
   ```
3. Set the Airflow User ID:
   * **macOS / Linux:**
     ```bash
     echo -e "AIRFLOW_UID=$(id -u)" > .env
     ```
   * **Windows (PowerShell):**
     ```powershell
     Set-Content -Path .env -Value "AIRFLOW_UID=50000"
     ```
4. Start the containers in the background:
   ```bash
   docker compose up -d
   ```
5. Verify that all services are running:
   ```bash
   docker compose ps
   ```

---

## 📥 Part 2: Database & Table Creation / การสร้างตารางและนำเข้าข้อมูล

### 1. Connect pgAdmin to PostgreSQL
1. Open your browser and go to: **[http://localhost:28880](http://localhost:28880)**
2. Log in with the default credentials:
   - **Email:** `dw_user@mail.com`
   - **Password:** `dw_pass`
3. Register the PostgreSQL Server:
   - Right-click **Servers** ➡️ **Register** ➡️ **Server...**
   - Under the **General** tab:
     - **Name:** `DW Postgres`
   - Under the **Connection** tab:
     - **Host name/address:** `dw_postgres` *(This is the internal Docker container name)*
     - **Port:** `5432`
     - **Maintenance database:** `airflow`
     - **Username:** `dw_user`
     - **Password:** `dw_pass`
   - Click **Save**.

### 2. Create the `sampledb` Database
1. In pgAdmin, right-click on your connected **DW Postgres** server ➡️ **Create** ➡️ **Database...**
2. **Database name:** `sampledb`
3. Click **Save**.

### 3. Create the `orders` Table
1. Select the newly created `sampledb` database in the left sidebar.
2. Open the **Query Tool** (Tools ➡️ Query Tool, or click the SQL icon).
3. Copy and paste the following SQL script, then click the **Execute/Play (F5)** button:

```sql
CREATE TABLE orders (
    row_id SERIAL PRIMARY KEY,
    order_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(20),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name TEXT,
    sales NUMERIC,
    quantity INT,
    discount NUMERIC,
    profit NUMERIC
);
```

### 4. Import the CSV Dataset
1. The dataset file `Sample - Superstore.csv` is located in the `week01-data-warehouse-setup/data/` folder.
2. In pgAdmin, expand **sampledb** ➡️ **Schemas** ➡️ **public** ➡️ **Tables**.
3. Right-click on the `orders` table ➡️ **Import/Export Data...**
4. Set the toggle to **Import**.
5. **Filename:** Click the folder icon and select the `Sample - Superstore.csv` file from the `data/` folder.
6. **Format:** Select `csv`.
7. Go to the **Options** tab:
   - **Header:** Set to `Yes` (to skip the first row of headers).
   - **Delimiter:** `,`
   - **Quote:** `"`
   - **Escape:** `"`
8. Click **OK**. Once completed, verify by running:
   ```sql
   SELECT * FROM orders LIMIT 10;
   ```

---

## 🌐 Part 3: Metabase Visualization / การเชื่อมต่อ Metabase

1. Open your browser and go to: **[http://localhost:23000](http://localhost:23000)**
2. Complete the initial setup/registration.
3. Add your database with the following details:
   - **Database type:** `PostgreSQL`
   - **Display name:** `sampledb`
   - **Host:** `dw_postgres` *(container name)*
   - **Port:** `5432`
   - **Database name:** `sampledb`
   - **Database username:** `dw_user`
   - **Database password:** `dw_pass`
4. Create your first Bar Chart:
   - Click **Explore** or **New** ➡️ **Question** ➡️ Select **sampledb** ➡️ **orders**.
   - Click **Visualization** and select **Bar**.
   - Set the axes:
     - **X-axis:** `Region`
     - **Y-axis:** `Sum of Sales` (or `Sales` grouped by `Region`).
   - Save the visualization.

---

## ✍️ Part 4: Analytical Questions / คำถามท้ายบทเรียน
*Answer these questions individually for your submission:*

1. Is the `orders` table an **OLTP** or **OLAP** schema? Why? / *ตาราง orders เป็น OLTP หรือ OLAP? เพราะเหตุใด*
2. If we were to integrate this `orders` table into a real Data Warehouse star schema, should it be designed as a **Fact Table** or a **Dimension Table**? / *หากนำตาราง orders นี้เข้าสู่ Data Warehouse จริง ควรออกแบบให้อยู่ในรูปแบบ Fact หรือ Dimension Table?*
3. Give 2 examples of Business Intelligence Dashboards/charts that can be built from this dataset to help managers make decisions. / *ยกตัวอย่าง Dashboard หรือชาร์ตวิเคราะห์ข้อมูล 2 แบบที่สามารถสร้างจากข้อมูลนี้เพื่อช่วยในการตัดสินใจของผู้บริหาร*

---

## 📤 Submission / สิ่งที่ต้องส่ง
Submit the following via the **[Google Form Assignment Link](https://docs.google.com/forms/d/e/1FAIpQLSd_yRfZwilZvGL-50gqBB0MZdWVC7WyzmToprNWWP0bAJfu4Q/viewform?usp=sharing&ouid=112034381246792911028)**:
1. **Screenshot** of your `orders` table visualization/exploration inside Metabase.
2. **Answers** to the 3 analytical questions in Part 4.

---

## 🛠️ Docker Cheat Sheet for this Lab

> ⚠️ **Note:** Always run these commands from inside the `week01-data-warehouse-setup/lab-week01` directory.

| Command | Description |
|---|---|
| `docker compose up -d` | Starts all services in the background. |
| `docker compose down` | Stops all services. |
| `docker compose down -v` | Stops services and **wipes all database data** (Full Reset). |
| `docker compose ps` | Checks the status of all containers. |
| `docker compose logs -f postgres` | Shows live logs for the PostgreSQL container. |

---

*Data Warehouse — DSBA8 | Week 1*

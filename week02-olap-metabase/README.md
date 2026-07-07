# 📦 Week 2: OLAP & Metabase — DW Architecture and Lifecycle

> **Course:** Data Warehousing (การสร้างคลังข้อมูล)  
> **Topic:** DW Architecture, Lifecycle & OLAP Operations with Metabase  
> **Duration:** 2 Hours

---

## 🎯 Learning Objectives / วัตถุประสงค์

1. Understand **Data Warehouse Architecture** and the DW Lifecycle.
2. Restore a real-world PostgreSQL database (`dvdrental`) using `pg_restore`.
3. Connect the database to **Metabase** and perform **OLAP-style** analysis.
4. Build interactive dashboards and answer business questions using visualizations.

---

## 🧰 Tools & Stack Overview / เครื่องมือที่ใช้

| Tool | What is it? | What is it used for in this lab? |
|---|---|---|
| **PostgreSQL 16** | Relational Database (RDBMS) | Stores the `dvdrental` sample database |
| **pgAdmin 4** | Database GUI Management Tool | Restore the `.tar` dump and run SQL queries |
| **Metabase** | Open-source BI & Visualization Tool | Build OLAP dashboards and charts |
| **dvdrental.tar** | PostgreSQL Database Dump | Sample DVD rental store database |

---

## 📁 Files in This Week / ไฟล์ในสัปดาห์นี้

| File / Folder | Description |
|---|---|
| 📂 [slides/](./slides/) | Lecture slides |
| └── 📄 [2 - DW Architecture & Lifecycle.pdf](./slides/2%20-%20DW%20Architecture%20%26%20Lifecycle.pdf) | Lecture: DW Architecture & Lifecycle |
| 📂 [docs/](./docs/) | Lab instructions |
| ├── 📄 [Lab2 Olap Metabase.pdf](./docs/Lab2%20Olap%20Metabase.pdf) | Lab instruction (PDF) |
| └── 📝 [Lab2 Olap Metabase.docx](./docs/Lab2%20Olap%20Metabase.docx) | Lab instruction (Word) |
| 📂 [lab-week02/](./lab-week02/) | Lab files |
| └── 🗄️ [dvdrental.tar](./lab-week02/dvdrental.tar) | PostgreSQL dvdrental database dump |

---

## 🔧 Part 1: Restore the dvdrental Database

### 1. Start the Stack
Make sure your Docker containers from Week 1 are running:
```bash
cd week01-data-warehouse-setup/lab-week01
docker compose up -d
docker compose ps
```

### 2. Create the `dvdrental` Database in pgAdmin

1. Open **[http://localhost:28880](http://localhost:28880)** and log in:
   - **Email:** `dw_user@mail.com`
   - **Password:** `dw_pass`
2. Connect to **DW Postgres** server (if not already connected).
3. Right-click **DW Postgres** ➡️ **Create** ➡️ **Database...**
   - **Database name:** `dvdrental`
   - Click **Save**

### 3. Copy the Dump File into the PostgreSQL Container

Open a terminal and run:
```bash
docker cp "/path/to/lab-week02/dvdrental.tar" dw_postgres:/tmp/dvdrental.tar
```

> Replace `/path/to/` with the actual path to your `lab-week02` folder.

### 4. Restore the Database

```bash
docker exec -it dw_postgres pg_restore \
  -U dw_user \
  -d dvdrental \
  /tmp/dvdrental.tar
```

### 5. Verify the Restore

In pgAdmin, open the **Query Tool** on the `dvdrental` database and run:
```sql
-- List all tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Quick row count check
SELECT COUNT(*) FROM rental;
SELECT COUNT(*) FROM film;
SELECT COUNT(*) FROM customer;
```

---

## 🗄️ Part 2: Explore the dvdrental Schema

The `dvdrental` database simulates a DVD rental store. Key tables:

| Table | Description |
|---|---|
| `film` | Movie catalog (title, rating, rental_rate, length) |
| `customer` | Customer information |
| `rental` | Rental transactions (rental_date, return_date) |
| `payment` | Payment records per rental |
| `inventory` | Physical copies of each film |
| `category` | Film genre/category |
| `actor` | Actor information |
| `store` | Store locations |

**Useful exploratory queries:**
```sql
-- Total revenue
SELECT SUM(amount) AS total_revenue FROM payment;

-- Top 10 most rented films
SELECT f.title, COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.title
ORDER BY rental_count DESC
LIMIT 10;

-- Revenue by film category
SELECT c.name AS category, SUM(p.amount) AS revenue
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.name
ORDER BY revenue DESC;

-- Monthly rental trend
SELECT DATE_TRUNC('month', rental_date) AS month,
       COUNT(*) AS rentals
FROM rental
GROUP BY month
ORDER BY month;
```

---

## 🌐 Part 3: Connect dvdrental to Metabase

1. Open **[http://localhost:23000](http://localhost:23000)**
2. Go to **Settings** (⚙️ top right) ➡️ **Admin settings** ➡️ **Databases** ➡️ **Add database**
3. Fill in the connection details:
   - **Database type:** `PostgreSQL`
   - **Display name:** `dvdrental`
   - **Host:** `dw_postgres` *(Docker container name — NOT localhost)*
   - **Port:** `5432`
   - **Database name:** `dvdrental`
   - **Username:** `dw_user`
   - **Password:** `dw_pass`
4. Click **Save** and wait for the sync to complete.

---

## 📊 Part 4: OLAP Analysis in Metabase

Build the following visualizations using **New ➡️ Question** or **SQL Query**:

### Chart 1 — Revenue by Film Category (Bar Chart)
- **X-axis:** Category name
- **Y-axis:** Sum of payment amount
- **Type:** Bar Chart

### Chart 2 — Monthly Rental Trend (Line Chart)
- **X-axis:** Rental date (grouped by Month)
- **Y-axis:** Count of rentals
- **Type:** Line Chart

### Chart 3 — Top 10 Most Rented Films (Table or Bar)
- Show film title + rental count
- Sort descending

### Chart 4 — Customer Revenue Distribution (Pie or Bar)
- Group by customer, show total amount paid

> 💡 Use **Metabase SQL Editor** (New ➡️ SQL Query) for complex joins that the GUI builder can't handle.

---

## ✍️ Part 5: Analytical Questions / คำถามท้ายบทเรียน

*Answer these questions individually for your submission:*

1. What is the difference between **OLTP** and **OLAP**? Which type does the `dvdrental` database represent after importing into a DW context? / *OLTP และ OLAP ต่างกันอย่างไร และ dvdrental จัดอยู่ในประเภทใด?*

2. Which **film category** generates the most revenue? What business decision could be made from this insight? / *ประเภทหนังที่สร้างรายได้สูงสุดคืออะไร? ควรตัดสินใจทางธุรกิจอย่างไร?*

3. Is there a seasonal pattern in rental activity? (Hint: look at the monthly trend chart.) / *มีรูปแบบตามฤดูกาลของการเช่าหรือไม่?*

---

## 📤 Submission / สิ่งที่ต้องส่ง

Submit the following via the **[Google Form Assignment Link](https://docs.google.com/forms/d/e/1FAIpQLSd_yRfZwilZvGL-50gqBB0MZdWVC7WyzmToprNWWP0bAJfu4Q/viewform?usp=sharing&ouid=112034381246792911028)**:
1. **Screenshots** of at least 2 Metabase charts you built.
2. **Answers** to the 3 analytical questions in Part 5.

---

## 🛠️ Useful Commands Cheat Sheet

> ⚠️ Run Docker commands from inside the `week01-data-warehouse-setup/lab-week01` directory.

| Command | Description |
|---|---|
| `docker compose up -d` | Start all services in background |
| `docker compose down` | Stop all services |
| `docker compose ps` | Check container status |
| `docker cp <file> dw_postgres:/tmp/` | Copy a file into the PostgreSQL container |
| `docker exec -it dw_postgres psql -U dw_user -d dvdrental` | Open psql shell in the container |
| `docker exec -it dw_postgres pg_restore -U dw_user -d dvdrental /tmp/dvdrental.tar` | Restore a `.tar` dump |

---

*Data Warehouse — DSBA8 | Week 2*

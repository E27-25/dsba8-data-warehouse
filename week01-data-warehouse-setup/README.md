# 📦 Week 1 — Data Warehouse Setup
> **Topic:** Data Warehouse Architecture + Environment Setup (Docker)

---

## 🎯 Learning Objectives

- Understand the **Data Warehouse** concept and architecture
- Set up a complete DWH stack using **Docker Compose**
- Get familiar with: **PostgreSQL**, **pgAdmin**, **Apache Airflow**, **dbt**, and **Metabase**
- Connect tools to form an end-to-end data pipeline environment

---

## 🏗️ Stack Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Network: dw_net                │
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │  PostgreSQL  │    │   pgAdmin   │    │  Metabase   │  │
│  │  port 25432  │◄───│  port 28880 │    │  port 23000 │  │
│  └──────┬──────┘    └─────────────┘    └──────┬──────┘  │
│         │                                      │        │
│         │           ┌─────────────┐            │        │
│         └───────────│     dbt     │────────────┘        │
│                     │  port 28088 │                     │
│                     └─────────────┘                     │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Apache Airflow                       │   │
│  │  API Server (28080) · Scheduler · DAG Processor  │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Services & Ports

| Service | Container Name | Port | Credentials |
|---|---|---|---|
| **PostgreSQL 16** | `dw_postgres` | `localhost:25432` | user: `dw_user` / pass: `dw_pass` |
| **pgAdmin 4** | `dw_pgadmin` | `http://localhost:28880` | email: `dw_user@mail.com` / pass: `dw_pass` |
| **Metabase** | `dw_metabase` | `http://localhost:23000` | — (setup on first run) |
| **dbt** | `dw_dbt` | — | — |
| **Airflow API** | — | `http://localhost:28080` | user: `airflow` / pass: `airflow` |

---

## 📁 Files in This Week

| File / Folder | Description |
|---|---|
| 📂 [docs/](./docs/) | Contains lab instructions and assignments. |
| ├── 📄 [Lab1 Data Warehouse Setup.docx](./docs/Lab1%20Data%20Warehouse%20Setup.docx) | Lab instruction document (Word). |
| └── 📄 [Lab1 Data Warehouse Setup.pdf](./docs/Lab1%20Data%20Warehouse%20Setup.pdf) | Lab instruction document (PDF). |
| 📂 [lab-week01/](./lab-week01/) | Contains environment setup files. |
| ├── 🐳 [docker-compose.yaml](./lab-week01/docker-compose.yaml) | Full stack definition (PostgreSQL, Airflow, dbt, Metabase, pgAdmin). |
| ├── 🐳 [dockerfile.airflow](./lab-week01/dockerfile.airflow) | Custom Airflow image with `git`, `dbt-core`, and `dbt-postgres` installed. |
| ├── ⚙️ [postgresql.conf](./lab-week01/postgresql.conf) | Custom PostgreSQL configuration. |
| └── 📦 [DWH_Lab.zip](./lab-week01/DWH_Lab.zip) | Complete lab archive. |

---

## 🚀 Getting Started

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- At least **4 GB RAM** and **10 GB disk** free for Docker

### Step 1: Navigate to the lab folder

```bash
cd week01-data-warehouse-setup/lab-week01
```

### Step 2: Set Airflow user ID (Linux/Mac)

```bash
echo -e "AIRFLOW_UID=$(id -u)" > .env
```

### Set Airflow user ID (Windows)
```bash
Set-Content -Path .env -Value "AIRFLOW_UID=50000"
```

### Step 3: Start all services

```bash
docker compose up -d
```

> ⏳ First run takes a few minutes — Airflow init must complete before the scheduler starts.

### Step 4: Verify everything is running

```bash
docker compose ps
```

You should see all containers with status `healthy` or `running`.

### Step 5: Access the tools

| Tool | URL |
|---|---|
| Airflow | http://localhost:28080 |
| pgAdmin | http://localhost:28880 |
| Metabase | http://localhost:23000 |

---

## 🔧 Common Commands

> ⚠️ **Note:** Always run these commands from inside the `week01-data-warehouse-setup/lab-week01` directory.

```bash
# Start all services in background
docker compose up -d

# Stop all services
docker compose down

# Stop and remove volumes (FULL RESET — loses all data)
docker compose down -v

# View logs of a specific service
docker compose logs -f postgres
docker compose logs -f airflow-scheduler

# Restart a single service
docker compose restart airflow-scheduler

# Enter a running container
docker compose exec postgres bash
docker compose exec dbt bash
```

---

## 🗄️ Connect pgAdmin to PostgreSQL

1. Open **pgAdmin** → `http://localhost:28880`
2. Login: `dw_user@mail.com` / `dw_pass`
3. Right-click **Servers** → **Register** → **Server**
4. Fill in:
   - **Name:** `DW Postgres`
   - **Host:** `dw_postgres` *(container name, not localhost)*
   - **Port:** `5432` *(internal Docker port)*
   - **Username:** `dw_user`
   - **Password:** `dw_pass`
5. Click **Save**

> ⚠️ Inside Docker, use `dw_postgres:5432`. From your host machine, use `localhost:25432`.

---

## 🌿 Using dbt

> ⚠️ **Note:** Run these commands from inside the `week01-data-warehouse-setup/lab-week01` directory.

```bash
# Enter the dbt container
docker compose exec dbt bash

# Inside the container — initialize a new dbt project
dbt init my_project

# Run dbt models
dbt run

# Test dbt models
dbt test

# Generate and serve docs
dbt docs generate
dbt docs serve --port 8080
```

---

## 📌 Tips & Troubleshooting

> ⚠️ **Airflow not starting?** Make sure the `airflow-init` container finishes successfully first.  
> Check with: `docker compose logs airflow-init`

> 💡 **Port already in use?** Another service on your machine may be using the same port. Stop it or change the port mapping in `docker-compose.yaml`.

> 🔁 **Changes to `dockerfile.airflow`?** Rebuild the image with:  
> `docker compose build && docker compose up -d`

> 🗂️ **Airflow DAGs folder** is mounted at `./dags` — create your `.py` DAG files there and Airflow will pick them up automatically.

---

## 🏛️ Data Warehouse Concept (Quick Review)

| Layer | Purpose | Example Tools |
|---|---|---|
| **Source** | Raw operational data | Databases, APIs, Files |
| **Staging** | Load & clean raw data | Airflow + PostgreSQL |
| **Warehouse** | Structured, query-ready data | PostgreSQL (fact/dim tables) |
| **Mart** | Business-specific views | dbt models |
| **BI / Reporting** | Visualize insights | Metabase |

---

*Data Warehouse — DSBA8 | Week 1*

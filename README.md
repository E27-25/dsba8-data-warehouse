<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,19,24&height=200&section=header&text=Data%20Warehouse&fontSize=48&fontColor=fff&animation=twinkling&fontAlignY=38&desc=DSBA8%20%7C%20King%20Mongkut%27s%20Institute%20of%20Technology%20Ladkrabang&descAlignY=58&descSize=16" width="100%"/>

<p>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Apache%20Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white"/>
  <img src="https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white"/>
  <img src="https://img.shields.io/badge/Metabase-509EE3?style=for-the-badge&logo=metabase&logoColor=white"/>
</p>

<p>
  <img src="https://img.shields.io/badge/Semester-1%2F2569-blueviolet?style=flat-square"/>
  <img src="https://img.shields.io/badge/Stack-Docker%20Compose-2496ED?style=flat-square"/>
  <img src="https://img.shields.io/badge/DB-PostgreSQL%2016-4169E1?style=flat-square"/>
  <img src="https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square"/>
</p>

</div>

---

## 📖 About This Course

> **Data Warehouse** covers the design and implementation of modern data warehouse systems. Students will build end-to-end data pipelines using industry-standard tools — from ingestion with **Apache Airflow**, transformation with **dbt**, storage in **PostgreSQL**, to visualization with **Metabase**.

---

## 🗓️ Course Schedule

| Week | Topic | Materials |
|:---:|---|:---:|
| 1 | Data Warehouse Setup (Docker Environment) | [Week 1](./week01-data-warehouse-setup/) |
| 2 | OLAP Operations with Metabase & PostgreSQL | [Week 2](./week02-olap-metabase/) |
| 3–15 | Coming soon — syllabus in progress | — |

---

## 🚀 Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- At least **4 GB RAM** and **10 GB disk** free

### 1. Clone the repository

```bash
git clone https://github.com/E27-25/dsba8-data-warehouse.git
cd dsba8-data-warehouse
```

### 2. Go to Week 1

```bash
cd week01-data-warehouse-setup/lab-week01
```

### 3. Start the full stack

```bash
echo -e "AIRFLOW_UID=$(id -u)" > .env
docker compose up -d
```

---

## 🏗️ Stack Overview

| Service | Role | Port |
|---|---|---|
| PostgreSQL 16 | Data Warehouse storage | `localhost:25432` |
| pgAdmin 4 | DB management UI | `http://localhost:28880` |
| Apache Airflow | Pipeline orchestration | `http://localhost:28080` |
| dbt | Data transformation | — |
| Metabase | BI & visualization | `http://localhost:23000` |

---

## 📁 Repository Structure

<details>
<summary><b>Expand to view full repository tree</b></summary>

```text
dsba8-data-warehouse/
│
├── README.md
│
├── week01-data-warehouse-setup/           ← Week 1 ✅
│   ├── docs/                              ← Lab instructions & documents
│   │   ├── Lab1 Data Warehouse Setup.docx
│   │   └── Lab1 Data Warehouse Setup.pdf
│   ├── slides/                            ← Lecture slides (PDF)
│   │   ├── 1 - Introduction to Data Warehouse.pdf
│   │   └── Overview.pdf
│   ├── data/                              ← Dataset files
│   │   └── Sample - Superstore.csv
│   ├── lab-week01/                        ← Lab environment files
│   │   ├── docker-compose.yaml
│   │   ├── dockerfile.airflow
│   │   ├── postgresql.conf
│   │   └── DWH_Lab.zip
│   └── README.md
│
└── week02-olap-metabase/                  ← Week 2 ✅
    ├── docs/                              ← Lab documentation & screenshots
    │   ├── Lab2 Olap Metabase.pdf
    │   └── screenshots/
    ├── data/                              ← Sample database
    │   └── DWH_Lab.zip
    └── README.md
```

</details>

---

## 🛠️ Tools & Technologies

<div align="center">

| Infrastructure | Data Layer | Visualization |
|---|---|---|
| Docker Compose | PostgreSQL 16 | Metabase |
| Apache Airflow 3.x | dbt Core | pgAdmin 4 |
| Custom Airflow Image | dbt-postgres | — |

</div>

---

## 📌 Key Ports Reference

```
localhost:25432  →  PostgreSQL
localhost:28080  →  Airflow API Server
localhost:28880  →  pgAdmin 4
localhost:23000  →  Metabase
```

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,19,24&height=100&section=footer&animation=twinkling" width="100%"/>

**Data Warehouse · DSBA8 · KMITL**

*Made with ❤️ for students*

</div>

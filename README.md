<div align="center">

<!-- Animated Banner -->
<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,19,24&height=200&section=header&text=Data%20Warehouse&fontSize=48&fontColor=fff&animation=twinkling&fontAlignY=38&desc=DSBA8%20%7C%20King%20Mongkut%27s%20University%20of%20Technology%20Thonburi&descAlignY=58&descSize=16" width="100%"/>

<!-- Badges -->
<p>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Apache%20Airflow-017CEE?style=for-the-badge&logo=apacheairflow&logoColor=white"/>
  <img src="https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white"/>
  <img src="https://img.shields.io/badge/Metabase-509EE3?style=for-the-badge&logo=metabase&logoColor=white"/>
</p>

<p>
  <img src="https://img.shields.io/badge/Semester-2%2F2568-blueviolet?style=flat-square"/>
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
| **1** | 🐳 Data Warehouse Setup (Docker Environment) | [📂 Week 1](./week01-data-warehouse-setup/) |
| **2–15** | 🔜 Coming soon — syllabus in progress | — |

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
cd week01-data-warehouse-setup
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
| 🐘 **PostgreSQL 16** | Data Warehouse storage | `localhost:25432` |
| 🔧 **pgAdmin 4** | DB management UI | `http://localhost:28880` |
| 🌊 **Apache Airflow** | Pipeline orchestration | `http://localhost:28080` |
| 🌿 **dbt** | Data transformation | — |
| 📊 **Metabase** | BI & visualization | `http://localhost:23000` |

---

## 📁 Repository Structure

```
dsba8-data-warehouse/
│
├── 📄 README.md                              ← You are here
│
└── 📂 week01-data-warehouse-setup/           ← Week 1 ✅
    ├── 📂 slides/                            ← Lecture slides (PDF)
    ├── 📂 docs/                              ← Lab instructions & worksheets
    │   └── Lab1 Data Warehouse Setup.docx
    ├── 🐳 docker-compose.yaml                ← Full stack definition
    ├── 🐳 dockerfile.airflow                 ← Custom Airflow image
    ├── ⚙️  postgresql.conf                   ← PostgreSQL config
    ├── 📦 DWH_Lab.zip                        ← Lab archive
    └── 📄 README.md                          ← Setup guide + lab notes
```

---

## 🛠️ Tools & Technologies

<div align="center">

| 🐳 Infrastructure | 🗄️ Data Layer | 📊 Visualization |
|---|---|---|
| Docker Compose | PostgreSQL 16 | Metabase |
| Apache Airflow 3.x | dbt Core | pgAdmin 4 |
| Custom Airflow Image | dbt-postgres | — |

</div>

---

## 📌 Key Ports Reference

```
localhost:25432  →  PostgreSQL  (from host machine)
localhost:28080  →  Airflow API Server
localhost:28880  →  pgAdmin 4
localhost:23000  →  Metabase
localhost:28088  →  dbt (container internal)
```

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,19,24&height=100&section=footer&animation=twinkling" width="100%"/>

**Data Warehouse · DSBA8 · KMITL**

*Made with ❤️ for students*

</div>

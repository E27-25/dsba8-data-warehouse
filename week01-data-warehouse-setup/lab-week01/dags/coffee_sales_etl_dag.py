from pathlib import Path

import psycopg2
import pendulum
from airflow.sdk import dag, task
from airflow.providers.standard.operators.bash import BashOperator


CSV_PATH = Path("/home/raw_data/coffee_sales.csv")


@dag(
    dag_id="coffee_sales_etl",
    description="Load coffee sales and build a star schema with dbt",
    start_date=pendulum.datetime(2026, 1, 1, tz="UTC"),
    schedule=None,
    catchup=False,
    default_args={"retries": 1},
    tags=["lab", "dbt", "warehouse"],
)
def coffee_sales_etl():

    @task
    def check_source_file():
        if not CSV_PATH.exists():
            raise FileNotFoundError(f"Source file not found: {CSV_PATH}")

        with CSV_PATH.open("r", encoding="utf-8-sig") as file:
            row_count = sum(1 for _ in file) - 1

        if row_count <= 0:
            raise ValueError("The CSV file has no data rows")

        print(f"Found {row_count:,} rows in {CSV_PATH}")
        return row_count

    @task
    def load_raw_csv():
        columns = """
            sale_id, invoice_number, sale_date, customer_code,
            customer_name, gender, birth_year, product_code,
            product_name, category, size, unit_price, quantity,
            revenue, store_code, store_name, province, staff_code,
            staff_name, position, promo_code, promo_desc,
            points_redeemed
        """

        create_table_sql = """
            create schema if not exists raw;
            create table if not exists raw.coffee_sales (
                sale_id text,
                invoice_number text,
                sale_date text,
                customer_code text,
                customer_name text,
                gender text,
                birth_year text,
                product_code text,
                product_name text,
                category text,
                size text,
                unit_price text,
                quantity text,
                revenue text,
                store_code text,
                store_name text,
                province text,
                staff_code text,
                staff_name text,
                position text,
                promo_code text,
                promo_desc text,
                points_redeemed text
            );
            truncate table raw.coffee_sales;
        """

        connection = psycopg2.connect(
            host="postgres",
            port=5432,
            dbname="lab10",
            user="dw_user",
            password="dw_pass",
        )

        try:
            with connection.cursor() as cursor:
                cursor.execute(create_table_sql)
                with CSV_PATH.open("r", encoding="utf-8-sig") as file:
                    cursor.copy_expert(
                        f"""
                        copy raw.coffee_sales ({columns})
                        from stdin with (format csv, header true)
                        """,
                        file,
                    )
                cursor.execute("select count(*) from raw.coffee_sales")
                row_count = cursor.fetchone()[0]
            connection.commit()
        finally:
            connection.close()

        print(f"Loaded {row_count:,} rows into raw.coffee_sales")
        return row_count

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=(
            "dbt run "
            "--project-dir /opt/airflow/dbt "
            "--profiles-dir /opt/airflow/dbt_root"
        ),
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=(
            "dbt test "
            "--project-dir /opt/airflow/dbt "
            "--profiles-dir /opt/airflow/dbt_root"
        ),
    )

    @task
    def validate_warehouse():
        connection = psycopg2.connect(
            host="postgres",
            port=5432,
            dbname="lab10",
            user="dw_user",
            password="dw_pass",
        )
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    select
                        count(*) as fact_rows,
                        sum(quantity) as total_quantity,
                        sum(revenue) as total_revenue
                    from warehouse.fct_sales
                """)
                result = cursor.fetchone()
        finally:
            connection.close()

        print(
            "Warehouse summary: "
            f"rows={result[0]:,}, "
            f"quantity={result[1]:,}, "
            f"revenue={result[2]:,.2f}"
        )

    source_ok = check_source_file()
    raw_loaded = load_raw_csv()
    warehouse_ok = validate_warehouse()

    source_ok >> raw_loaded >> dbt_run >> dbt_test >> warehouse_ok


coffee_sales_etl()

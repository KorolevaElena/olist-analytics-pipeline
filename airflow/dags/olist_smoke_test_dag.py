from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

default_args = {
    "owner": "elena",
    "retries": 2,
    "retry_delay": 300,
}

with DAG(
    dag_id="olist_smoke_test",
    description="Проверка, что Airflow может обращаться к GCP",
    default_args=default_args,
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["olist", "smoke-test"],
) as dag:

    check_bq_access = BigQueryInsertJobOperator(
        task_id="check_bigquery_access",
        gcp_conn_id="google_cloud_default",  # какое подключение использовать (настроим ниже)
        configuration={
            "query": {
                "query": "SELECT COUNT(*) as row_count FROM `olist-analytics-pipeline.raw.orders`",
                "useLegacySql": False,
            }
        },
        location="us-central1",  # тот же регион, где мы создавали BQ датасеты
    )

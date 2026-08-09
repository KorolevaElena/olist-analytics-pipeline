from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.models import Variable
from datetime import datetime
import os

GCS_BUCKET = "olist-raw-ekoroleva"
BQ_PROJECT = "olist-analytics-pipeline"
BQ_DATASET = "raw"
LOCAL_DATA_DIR = "/opt/airflow/data/raw"

# Список файлов и их целевых таблиц — единый source of truth,
# на него опираются несколько task ниже
TABLES = {
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "products": "olist_products_dataset.csv",
    "customers": "olist_customers_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

# Ожидаемые row counts для data quality проверки —
# то же самое, что мы сверяли руками в Phase 1
EXPECTED_ROW_COUNTS = {
    "orders": 99441, "order_items": 112650, "order_payments": 103886,
    "order_reviews": 99224, "products": 32951, "customers": 99441,
    "sellers": 3095, "geolocation": 1000163, "category_translation": 71,
}


def download_kaggle_data(**context):
    """Скачивает датасет с Kaggle, используя токен из Airflow Variables."""
    import os

    # Кладём токен в файл ДО импорта kaggle-библиотеки —
    # современный kaggle CLI (2.x) ищет именно ~/.kaggle/access_token
    kaggle_dir = os.path.expanduser("~/.kaggle")
    os.makedirs(kaggle_dir, exist_ok=True)
    token = Variable.get("kaggle_api_token")
    with open(f"{kaggle_dir}/access_token", "w") as f:
        f.write(token)
    os.chmod(f"{kaggle_dir}/access_token", 0o600)

    from kaggle.api.kaggle_api_extended import KaggleApi

    api = KaggleApi()
    api.authenticate()
    os.makedirs(LOCAL_DATA_DIR, exist_ok=True)
    api.dataset_download_files(
        "olistbr/brazilian-ecommerce", path=LOCAL_DATA_DIR, unzip=True
    )
    print(f"Скачано в {LOCAL_DATA_DIR}: {os.listdir(LOCAL_DATA_DIR)}")

def fix_order_reviews(**context):
    """
    Data quality fix: order_reviews.csv содержит незаэкранированные кавычки
    в свободном тексте отзывов, что ломает строгий CSV-парсер BigQuery.
    Решение: читаем через pandas (терпимее к кривому CSV) и сохраняем в Parquet
    (бинарный формат, не подвержен этой проблеме).
    """
    import pandas as pd

    src = f"{LOCAL_DATA_DIR}/olist_order_reviews_dataset.csv"
    df = pd.read_csv(src, dtype=str, keep_default_na=False, on_bad_lines="warn")
    print(f"order_reviews: прочитано {len(df)} строк")

    dst = f"{LOCAL_DATA_DIR}/olist_order_reviews_dataset.parquet"
    df.to_parquet(dst, index=False)
    print(f"Сохранено в {dst}")


def upload_to_gcs(**context):
    """Заливает все локальные файлы (CSV + фикшенный Parquet) в GCS landing zone."""
    from google.cloud import storage

    client = storage.Client()
    bucket = client.bucket(GCS_BUCKET)

    files_to_upload = list(TABLES.values()) + ["olist_order_reviews_dataset.parquet"]
    for filename in files_to_upload:
        local_path = f"{LOCAL_DATA_DIR}/{filename}"
        blob = bucket.blob(f"raw/{filename}")
        blob.upload_from_filename(local_path, timeout=300)
        print(f"Загружено: {filename} -> gs://{GCS_BUCKET}/raw/{filename}")


def load_tables_to_bigquery(**context):
    """
    Грузит все 8 CSV-таблиц + 1 Parquet (order_reviews) из GCS в BigQuery raw dataset.
    CSV и Parquet требуют разных LoadJobConfig — обрабатываем каждый тип отдельно.
    """
    from google.cloud import bigquery

    client = bigquery.Client(project=BQ_PROJECT)

    # Обычные CSV-таблицы
    for table_name, filename in TABLES.items():
        uri = f"gs://{GCS_BUCKET}/raw/{filename}"
        table_id = f"{BQ_PROJECT}.{BQ_DATASET}.{table_name}"
        job_config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            autodetect=True,
            write_disposition="WRITE_TRUNCATE",  # аналог --replace
        )
        load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)
        load_job.result()  # ждём завершения job перед следующей итерацией
        print(f"Загружено: {table_name} ({load_job.output_rows} строк)")

    # order_reviews — отдельно, через Parquet
    uri = f"gs://{GCS_BUCKET}/raw/olist_order_reviews_dataset.parquet"
    table_id = f"{BQ_PROJECT}.{BQ_DATASET}.order_reviews"
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.PARQUET,
        write_disposition="WRITE_TRUNCATE",
    )
    load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)
    load_job.result()
    print(f"Загружено: order_reviews ({load_job.output_rows} строк)")


def validate_row_counts(**context):
    """
    Data quality gate: сверяем фактическое количество строк в каждой таблице
    с ожидаемым. Если расхождение больше допустимого порога — падаем,
    чтобы не пропустить битые данные дальше по pipeline (в staging/marts).
    """
    from google.cloud import bigquery

    client = bigquery.Client(project=BQ_PROJECT)
    errors = []

    for table_name, expected in EXPECTED_ROW_COUNTS.items():
        query = f"SELECT COUNT(*) as cnt FROM `{BQ_PROJECT}.{BQ_DATASET}.{table_name}`"
        actual = list(client.query(query).result())[0]["cnt"]
        diff_pct = abs(actual - expected) / expected * 100

        status = "OK" if diff_pct < 1 else "MISMATCH"
        print(f"{table_name}: expected={expected}, actual={actual}, diff={diff_pct:.2f}% [{status}]")

        if diff_pct >= 1:
            errors.append(f"{table_name}: expected {expected}, got {actual}")

    if errors:
        raise ValueError(f"Data quality check failed:\n" + "\n".join(errors))

    print("Все row counts в пределах ожидаемых значений")


default_args = {
    "owner": "elena",
    "retries": 2,
    "retry_delay": 300,
}

with DAG(
    dag_id="olist_full_pipeline",
    description="Kaggle -> GCS -> BigQuery raw layer, с data quality gate",
    default_args=default_args,
    schedule=None,
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["olist", "pipeline"],
) as dag:

    t1_download = PythonOperator(
        task_id="download_kaggle_data",
        python_callable=download_kaggle_data,
    )

    t2_fix_reviews = PythonOperator(
        task_id="fix_order_reviews_csv",
        python_callable=fix_order_reviews,
    )

    t3_upload = PythonOperator(
        task_id="upload_to_gcs",
        python_callable=upload_to_gcs,
    )

    t4_load = PythonOperator(
        task_id="load_tables_to_bigquery",
        python_callable=load_tables_to_bigquery,
    )

    t5_validate = PythonOperator(
        task_id="validate_row_counts",
        python_callable=validate_row_counts,
    )

    # Зависимости: строго последовательно, каждый шаг требует предыдущий
    t1_download >> t2_fix_reviews >> t3_upload >> t4_load >> t5_validate

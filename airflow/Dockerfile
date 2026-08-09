FROM apache/airflow:2.10.4-python3.12

RUN pip install --no-cache-dir \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.10.4/constraints-3.12.txt" \
    apache-airflow-providers-google \
    kaggle==2.2.3 \
    google-cloud-storage==2.19.0 \
    pandas \
    pyarrow==18.1.0

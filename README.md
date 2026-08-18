# Olist E-commerce Analytics Pipeline

An end-to-end analytics engineering project built on the public Brazilian
Olist e-commerce dataset — from raw ingestion to an executive-ready BI layer.
Designed and built as a hands-on exercise in BigQuery, dbt, and Airflow, with
a deliberate focus on data quality practices throughout every layer.

**Stack:** Kaggle → GCS → BigQuery (raw / staging / marts) → dbt (transformation
& testing), orchestrated by Airflow, fully containerized with Docker Compose.

---

## Architecture

```
Kaggle dataset
      │
      ▼
  Airflow DAG (olist_full_pipeline)
      │   Kaggle → GCS → BigQuery raw
      │   data quality gate on row counts
      ▼
  BigQuery: raw dataset (9 tables, validated against source)
      │
      ▼
  dbt: staging layer (9 models, 1:1 with source schema, cleaned types/names)
      │
      ▼
  dbt: marts / core (4 dimensions + 4 facts, Kimball-style)
      │
      ▼
  dbt: marts / reporting (8 tables, one per dashboard need)
      │
      ▼
  BI dashboard (4 pages, executive-focused)
```

- **GCP project:** `olist-analytics-pipeline`, BigQuery datasets in `us-central1`
- **Airflow:** Docker Compose, custom image, DAG `olist_full_pipeline`
- **dbt:** separate Docker Compose service, BigQuery service account with
  least-privilege roles
- **Custom schema macro** (`generate_schema_name`) routes `staging` and
  `marts` models to distinct BigQuery datasets instead of dbt's default
  concatenated schema naming.

---

## Data Layers

### Raw
9 Olist tables loaded from Kaggle via Airflow, row counts validated against
source before the pipeline is allowed to proceed (data quality gate).

### Staging (9/9 models)
`stg_orders`, `stg_customers`, `stg_order_items`, `stg_order_payments`,
`stg_order_reviews`, `stg_products`, `stg_sellers`, `stg_geolocation`,
`stg_category_translation`

One-to-one with source schema: renamed/typed columns, no business logic.
**57 dbt tests** — `not_null`, `unique`, `accepted_values`, `relationships`,
`accepted_range`, `unique_combination_of_columns`, `expression_is_true`.

### Marts — Core (Kimball-style dimensional model)

| Model | Grain |
|---|---|
| `dim_dates` | one calendar day (static calendar, independent of fact tables) |
| `dim_customers` | one customer (`customer_unique_id`; address resolved to most recent order, SCD Type 1) |
| `dim_products` | one product (LEFT JOIN to category translation, orphans preserved and flagged) |
| `dim_sellers` | one seller |
| `fct_order_items` | one item within one order |
| `fct_orders` | one order (header-level totals + dispatch/transit/delay time in hours) |
| `fct_order_payments` | one payment on an order (orders can have multiple) |
| `fct_reviews` | one review (`order_id` + `review_id`, since `review_id` is not guaranteed unique) |

### Marts — Reporting (denormalized, one purpose per dashboard need)

| Model | Grain |
|---|---|
| `mart_executive_summary` | one month |
| `mart_top_performers` | entity_type × period_type × direction × rank |
| `mart_product_performance` | category × month |
| `mart_catalog_quality` | one product (point-in-time snapshot) |
| `mart_seller_performance` | one seller (point-in-time snapshot) |
| `mart_customer_analysis` | one customer (point-in-time snapshot) |
| `mart_payment_preferences` | region × customer status × payment type |

---

## Dashboard

Four executive-focused pages, each backed by purpose-built reporting marts.

### 1. Executive Summary
GMV (goods only, excl. freight) + MoM growth, orders count + AOV, active
sellers/customers, rolling 3-month retention rate, % cancelled orders, %
on-time delivery, average review score, top/bottom-3 products/sellers/regions
by GMV contribution.

### 2. Product / Category Analysis
GMV and order volume by category with MoM growth, top/bottom performing
categories, and a catalog quality scorecard (missing category/name/description
/photos as "red" issues, short descriptions or too few photos as "yellow"
warnings) — designed to inform where to invest in catalog improvement.

### 3. Seller Performance
GMV and order volume per seller, delivery performance broken down by stage
(dispatch → carrier → customer, all in hours for consistency), on-time rate,
delivery time benchmarked against the seller's own region average, average
review score, and catalog quality by seller — to identify who to reward and
who needs support.

### 4. Customer Analysis
Customer status (`new` / `active` / `inactive`, based on a rolling 3-month
window anchored to the most recent complete month of data), geographic
distribution, and payment method preferences segmented by region and customer
status (including installment behavior and average payment value) — feeding
a retention strategy.

*A separate internal Data Quality dashboard (test results, documented issues)
was scoped but intentionally deprioritized — it belongs to the DE/support
function, not the executive-facing deliverable this project targets.*

---

## Data Quality Approach

Testing strategy differs by layer, reflecting what actually needs validating
at each stage:

- **Staging:** technical correctness — types, nulls, uniqueness, accepted
  ranges/values, matching the source schema.
- **Core marts:** grain integrity (`unique_combination_of_columns` on every
  fact table), referential integrity between facts and dimensions, and
  **reconciliation tests** — singular tests comparing aggregated sums between
  staging and marts to catch silent row duplication (JOIN fan-out) that
  structural tests alone wouldn't detect.
- **Reporting marts:** business-logic assertions (rates bounded 0–1, no
  negative GMV) and explicit handling of legitimate `NULL`s at data
  boundaries (e.g. delivery metrics for undelivered orders, growth metrics
  on a cohort's first observed month).

Severity (`error` vs `warn`) is assigned based on **investigated evidence**,
not assumption — e.g. product category mismatches are `warn` (a known,
sizeable, expected gap in the source), while an order line item with no
matching order at all is `error` (should never happen, and empirically
doesn't, in this dataset).

### Documented Data Quality Issues

**Staging (6):** duplicate `zip_code_prefix` rows in geolocation, orphan
products with no matching category translation, duplicate `review_id`s
(intentionally not deduplicated — no reliable way to determine the correct
`order_id`), a typo in a source column name, and others — each classified
and reasoned about individually rather than blanket-fixed.

**Marts (10+), notable findings:**
- A **systemic pattern** of orphan child records — order items, payments,
  and reviews referencing an `order_id` absent from `orders` — appearing
  independently across three unrelated tables, suggesting an incomplete source export rather than isolated
  bugs.
- ~1% of `delivered` orders have delivery timestamps in an illogical order
  (carrier date after customer-received date) — a source logging issue, not
  a pipeline bug, confirmed by checking that the anomaly wasn't concentrated
  in `canceled`/`shipped` statuses.
- November 2016 has zero orders — an early, near-inactive month in the raw
  data, requiring `NULL`-safe (not `0`-defaulted) handling in rate metrics
  to avoid a misleading "0% cancellation" reading.
- The dataset's export cuts off mid-month (September 2018 has exactly 1
  order) — monthly aggregations filter to the last month with a meaningful
  order volume, not simply the calendar-latest month.

---

## Challenges & Solutions

- **CSV escaping in review text** broke standard CSV parsing → worked around
  via a pandas/Parquet intermediate step.
- **Headerless CSV** in `category_translation` required explicit column
  naming on load.
- **Kaggle API changes, JWT mismatch, network timeouts, package version
  conflicts** — resolved iteratively while building the ingestion DAG.
- **BigQuery dataset routing:** dbt's default schema behavior concatenates
  the target schema with any custom `+schema` config, which didn't fit a
  simple `raw`/`staging`/`marts` layout — solved with a project-level
  override of the `generate_schema_name` macro.
- **`ACCEPTED_VALUES` on boolean/integer columns** fails in BigQuery with a
  type mismatch (the test quotes values as strings by default) — fixed with
  `quote: false`.

---

## Running the Project

```bash
cd dbt
docker-compose up -d
docker-compose run --rm dbt deps                          # install packages
docker-compose run --rm dbt run --profiles-dir ./profiles  # build all models
docker-compose run --rm dbt test --profiles-dir ./profiles # run all tests
```

---

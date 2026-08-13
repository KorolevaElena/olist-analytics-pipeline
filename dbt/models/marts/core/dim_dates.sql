-- Grain: one row per calendar date
-- Статичная дименсия: не зависит от fact-таблиц, диапазон задан с запасом
-- вокруг фактического периода Olist-данных (2016-09 — 2018-10)

with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2020-12-31' as date)"
    ) }}

)

select
    date_day,
    extract(year from date_day)     as year,
    extract(month from date_day)    as month,
    format_date('%B', date_day)     as month_name,
    extract(quarter from date_day)  as quarter,
    extract(dayofweek from date_day) as day_of_week,   -- 1=Sunday ... 7=Saturday в BigQuery
    format_date('%A', date_day)     as day_name,
    extract(dayofweek from date_day) in (1, 7) as is_weekend

from date_spine
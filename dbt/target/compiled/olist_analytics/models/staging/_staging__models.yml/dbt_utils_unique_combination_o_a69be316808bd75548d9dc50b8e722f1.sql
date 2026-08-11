





with validation_errors as (

    select
        geolocation_zip_code_prefix, geolocation_lat, geolocation_lng
    from `olist-analytics-pipeline`.`staging`.`stg_geolocation`
    group by geolocation_zip_code_prefix, geolocation_lat, geolocation_lng
    having count(*) > 1

)

select *
from validation_errors



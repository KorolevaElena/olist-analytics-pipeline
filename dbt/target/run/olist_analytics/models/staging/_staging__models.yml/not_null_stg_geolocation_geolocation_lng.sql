select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select geolocation_lng
from `olist-analytics-pipeline`.`staging`.`stg_geolocation`
where geolocation_lng is null



      
    ) dbt_internal_test
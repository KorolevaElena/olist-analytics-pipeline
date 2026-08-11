-- Staging: geolocation data. NOTE: geolocation_zip_code_prefix is NOT
-- unique -- one zip prefix maps to multiple lat/lng points (different
-- exact locations within the same postal zone).

select
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state

from {{ source('raw', 'geolocation') }}

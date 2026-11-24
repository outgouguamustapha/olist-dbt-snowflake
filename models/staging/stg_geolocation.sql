with source as (
    select * from {{ source('olist_raw', 'raw_geolocation') }}
),

aggregated as (
    select
        geolocation_zip_code_prefix as zip_code_prefix,
        
        -- Centroid / median coordinates per postal zone
        avg(cast(geolocation_lat as float)) as latitude,
        avg(cast(geolocation_lng as float)) as longitude,
        
        -- Clean city and state (taking the most common spelling)
        initcap(trim(max(geolocation_city))) as city,
        upper(trim(max(geolocation_state))) as state

    from source
    group by geolocation_zip_code_prefix
)

select * from aggregated
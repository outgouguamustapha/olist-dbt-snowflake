with sellers as (
    select * from {{ ref('stg_sellers') }}
),

geo as (
    select * from {{ ref('stg_geolocation') }}
),

joined as (
    select
        -- Primary Key
        s.seller_id,
        
        -- Geographic attributes
        s.seller_zip_code_prefix,
        s.seller_city,
        s.seller_state,
        
        -- Centroid coordinates from geolocation
        g.latitude as seller_latitude,
        g.longitude as seller_longitude

    from sellers s
    left join geo g
        on s.seller_zip_code_prefix = g.zip_code_prefix
)

select * from joined
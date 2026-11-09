with source as (
    select * from {{ source('olist_raw', 'raw_sellers') }}
),

renamed as (
    select
        -- Primary Key
        seller_id,
        
        -- Geographic attributes
        seller_zip_code_prefix,
        initcap(trim(seller_city)) as seller_city,
        upper(trim(seller_state)) as seller_state

    from source
)

select * from renamed
with source as (
    select * from {{ source('olist_raw', 'raw_customers') }}
),

renamed as (
    select
        -- Transaction-level customer foreign key (1:1 with order)
        customer_id,
        
        -- Unique physical individual/business key
        customer_unique_id,
        
        -- Geographic attributes
        customer_zip_code_prefix as customer_zip_code_prefix,
        initcap(trim(customer_city)) as customer_city,
        upper(trim(customer_state)) as customer_state

    from source
)

select * from renamed
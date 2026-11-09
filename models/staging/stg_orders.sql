with source as (
    select * from {{ source('olist_raw', 'raw_orders') }}
),

renamed as (
    select
        -- Primary Key
        order_id,
        
        -- Foreign Key
        customer_id,
        
        -- Clean string dimensions
        lower(trim(order_status)) as order_status,
        
        -- Timestamps with safe casting
        try_to_timestamp_ntz(order_purchase_timestamp) as order_purchase_at,
        try_to_timestamp_ntz(order_approved_at) as order_approved_at,
        try_to_timestamp_ntz(order_delivered_carrier_date) as order_delivered_carrier_at,
        try_to_timestamp_ntz(order_delivered_customer_date) as order_delivered_customer_at,
        try_to_timestamp_ntz(order_estimated_delivery_date) as order_estimated_delivery_at

    from source
)

select * from renamed
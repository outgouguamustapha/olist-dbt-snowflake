with source as (
    select * from {{ source('olist_raw', 'raw_order_items') }}
),

renamed as (
    select
        -- Composite Primary Key identifier components
        order_id,
        order_item_id,
        
        -- Foreign Keys linking to Products and Sellers
        product_id,
        seller_id,
        
        -- Timestamps
        try_to_timestamp_ntz(shipping_limit_date) as shipping_limit_at,
        
        -- Financial metrics cast explicitly to numeric/float types
        cast(price as float) as item_price,
        cast(freight_value as float) as freight_value,
        
        -- Row-level calculated gross line total
        cast(price + freight_value as float) as line_item_total

    from source
)

select * from renamed
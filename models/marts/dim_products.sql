with products as (
    select * from {{ ref('stg_products') }}
),

transformed as (
    select
        product_id,
        product_category_name_en,
        product_category_name_pt,
        
        -- Physical dimensions
        product_name_char_length,
        product_description_char_length,
        product_photos_count,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,
        
        -- Volumetric size in cubic centimeters (cm³)
        cast(product_length_cm * product_height_cm * product_width_cm as float) as product_volume_cm3,
        
        -- Discrete logistics weight tier
        case
            when product_weight_g is null then 'Unknown'
            when product_weight_g <= 500 then 'Lightweight (<= 0.5kg)'
            when product_weight_g <= 2000 then 'Standard (0.5kg - 2kg)'
            when product_weight_g <= 5000 then 'Heavy (2kg - 5kg)'
            else 'Freight Bulk (> 5kg)'
        end as product_weight_tier

    from products
)

select * from transformed
with products as (
    select * from {{ source('olist_raw', 'raw_products') }}
),

translations as (
    select * from {{ source('olist_raw', 'raw_category_translation') }}
),

joined as (
    select
        -- Primary Key
        p.product_id,
        
        -- Category attributes with English fallback
        coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as product_category_name_en,
        coalesce(p.product_category_name, 'unknown') as product_category_name_pt,
        
        -- Product physical specifications & metrics (fixing typos from raw)
        cast(p.product_name_lenght as int) as product_name_char_length,
        cast(p.product_description_lenght as int) as product_description_char_length,
        cast(p.product_photos_qty as int) as product_photos_count,
        cast(p.product_weight_g as float) as product_weight_g,
        cast(p.product_length_cm as float) as product_length_cm,
        cast(p.product_height_cm as float) as product_height_cm,
        cast(p.product_width_cm as float) as product_width_cm

    from products p
    left join translations t
        on p.product_category_name = t.product_category_name
)

select * from joined
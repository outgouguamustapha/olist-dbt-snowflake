with source as (
    select * from {{ source('olist_raw', 'raw_order_reviews') }}
),

renamed as (
    select
        review_id,
        order_id,
        cast(review_score as int) as review_score,
        
        -- Text cleanup
        trim(review_comment_title) as review_comment_title,
        trim(review_comment_message) as review_comment_message,
        
        -- Timestamps
        try_to_timestamp_ntz(review_creation_date) as review_created_at,
        try_to_timestamp_ntz(review_answer_timestamp) as review_answered_at

    from source
)

select * from renamed
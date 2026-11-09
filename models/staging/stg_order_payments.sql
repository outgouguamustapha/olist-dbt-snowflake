with source as (
    select * from {{ source('olist_raw', 'raw_order_payments') }}
),

renamed as (
    select
        order_id,
        cast(payment_sequential as int) as payment_sequential,
        lower(trim(payment_type)) as payment_type,
        cast(payment_installments as int) as payment_installments,
        cast(payment_value as float) as payment_amount

    from source
)

select * from renamed
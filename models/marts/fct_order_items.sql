with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

final as (
    select
        -- Composite Surrogate / Natural Grain Keys
        {{ dbt_utils.generate_surrogate_key(['oi.order_id', 'oi.order_item_id']) }} as order_item_key,
        oi.order_id,
        oi.order_item_id,

        -- Foreign Dimension Keys
        oi.product_id,
        oi.seller_id,
        c.customer_unique_id,
        cast(to_char(o.order_purchase_at, 'YYYYMMDD') as integer) as order_date_key,
        cast(to_char(oi.shipping_limit_at, 'YYYYMMDD') as integer) as shipping_limit_date_key,

        -- Order Status & Timestamps
        o.order_status,
        o.order_purchase_at,
        oi.shipping_limit_at,
        o.order_delivered_carrier_at,
        o.order_delivered_customer_at,

        -- Financial Measures (Line-Item Grain)
        oi.item_price,
        oi.freight_value,
        oi.item_price + oi.freight_value as total_item_amount,

        -- Seller Dispatch Performance
        datediff('day', o.order_purchase_at, o.order_delivered_carrier_at) as seller_dispatch_days,
        datediff('day', oi.shipping_limit_at, o.order_delivered_carrier_at) as seller_dispatch_delay_days,
        case
            when o.order_delivered_carrier_at is null then 'Not Dispatched'
            when o.order_delivered_carrier_at <= oi.shipping_limit_at then 'Dispatched On Time'
            else 'Late Dispatch'
        end as seller_dispatch_status

    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id
    left join customers c
        on o.customer_id = c.customer_id
)

select * from final
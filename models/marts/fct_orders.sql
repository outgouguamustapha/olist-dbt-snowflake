with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

items as (
    select
        order_id,
        count(order_item_id) as total_items_count,
        count(distinct product_id) as distinct_products_count,
        count(distinct seller_id) as distinct_sellers_count,
        coalesce(sum(item_price), 0) as items_gross_amount,
        coalesce(sum(freight_value), 0) as freight_amount
    from {{ ref('stg_order_items') }}
    group by order_id
),

payments as (
    select
        order_id,
        -- Count of distinct payment transactions / split tenders used
        count(payment_sequential) as payment_tenders_count,
        -- Maximum credit installment terms selected (e.g., 1x, 3x, 10x)
        coalesce(max(payment_installments), 1) as max_payment_installments,
        -- Gross sum of all tenders applied
        coalesce(sum(payment_amount), 0) as total_payment_amount,
        -- Primary payment tender by financial share
        max_by(payment_type, payment_amount) as primary_payment_type
    from {{ ref('stg_order_payments') }}
    group by order_id
),

reviews as (
    select
        order_id,
        avg(review_score) as average_review_score,
        -- Peak rating submitted for this order
        max(review_score) as highest_review_score,
        -- Chronologically latest review score submitted
        max_by(review_score, review_created_at) as latest_review_score
    from {{ ref('stg_order_reviews') }}
    group by order_id
),

final as (
    select
        -- Primary Key
        o.order_id,

        -- Foreign Dimension Keys
        c.customer_unique_id,
        cast(to_char(o.order_purchase_at, 'YYYYMMDD') as integer) as order_date_key,

        -- Status & Timestamps
        o.order_status,
        o.order_purchase_at,
        o.order_approved_at,
        o.order_delivered_carrier_at,
        o.order_delivered_customer_at,
        o.order_estimated_delivery_at,

        -- Order Quantities & Variety
        coalesce(i.total_items_count, 0) as total_items_count,
        coalesce(i.distinct_products_count, 0) as distinct_products_count,
        coalesce(i.distinct_sellers_count, 0) as distinct_sellers_count,

        -- Financials & Payments
        coalesce(i.items_gross_amount, 0) as items_gross_amount,
        coalesce(i.freight_amount, 0) as freight_amount,
        coalesce(i.items_gross_amount, 0) + coalesce(i.freight_amount, 0) as total_order_amount,
        coalesce(p.total_payment_amount, 0) as total_payment_amount,
        p.primary_payment_type,
        coalesce(p.payment_tenders_count, 0) as payment_tenders_count,
        coalesce(p.max_payment_installments, 0) as max_payment_installments,

        -- Feedback
        r.average_review_score,
        r.highest_review_score,
        r.latest_review_score,

        -- Fulfillment & Logistics Lead Times
        datediff('day', o.order_purchase_at, o.order_delivered_customer_at) as actual_delivery_days,
        datediff('day', o.order_purchase_at, o.order_estimated_delivery_at) as estimated_delivery_days,
        datediff('day', o.order_estimated_delivery_at, o.order_delivered_customer_at) as delivery_delay_days,
        case 
            when o.order_delivered_customer_at is null then 'In Transit / Not Delivered'
            when o.order_delivered_customer_at <= o.order_estimated_delivery_at then 'On Time'
            else 'Delayed'
        end as delivery_lead_time_status

    from orders o
    left join customers c
        on o.customer_id = c.customer_id
    left join items i
        on o.order_id = i.order_id
    left join payments p
        on o.order_id = p.order_id
    left join reviews r
        on o.order_id = r.order_id
)

select * from final


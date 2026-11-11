with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

geo as (
    select * from {{ ref('stg_geolocation') }}
),

customer_orders_summary as (
    select
        c.customer_unique_id,
        min(o.order_purchase_at) as first_order_at,
        max(o.order_purchase_at) as most_recent_order_at,
        count(distinct o.order_id) as lifetime_orders_count

    from customers c
    inner join orders o
        on c.customer_id = o.customer_id
    group by c.customer_unique_id
),

final as (
    select
        -- Primary Key
        c.customer_unique_id,
        
        -- Geographic dimensions (deduplicated by latest known order)
        c.customer_city,
        c.customer_state,
        c.customer_zip_code_prefix,
        g.latitude as customer_latitude,
        g.longitude as customer_longitude,
        
        -- Behavioral & cohort metrics
        s.first_order_at,
        s.most_recent_order_at,
        s.lifetime_orders_count,
        case 
            when s.lifetime_orders_count > 1 then 'Repeat Buyer'
            else 'One-Time Buyer'
        end as customer_segment

    from customers c
    inner join customer_orders_summary s
        on c.customer_unique_id = s.customer_unique_id
    left join geo g
        on c.customer_zip_code_prefix = g.zip_code_prefix
    qualify row_number() over ( partition by c.customer_unique_id order by s.most_recent_order_at desc) = 1
)

select * from final

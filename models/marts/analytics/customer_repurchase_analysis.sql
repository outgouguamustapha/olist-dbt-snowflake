with orders as (
    select
        order_id,
        customer_unique_id,
        order_purchase_at,
        total_order_amount
    from {{ ref('fct_orders') }}
    where order_status != 'canceled'
),

sequenced_orders as (
    -- Assign lifetime order number (1 = first order ever, 2+ = repeat order)
    select
        order_id,
        customer_unique_id,
        order_purchase_at,
        total_order_amount,

        to_char(order_purchase_at, 'YYYY-MM') as sales_year_month,
        date_trunc('month', order_purchase_at)::date as month_start_date,

        row_number() over (
            partition by customer_unique_id 
            order by order_purchase_at asc
        ) as customer_order_sequence

    from orders
),

monthly_summary as (
    select
        sales_year_month,
        month_start_date,

        -- Order breakdown
        count(order_id) as total_orders,
        count(case when customer_order_sequence = 1 then order_id end) as first_time_orders,
        count(case when customer_order_sequence > 1 then order_id end) as repeat_orders,

        -- Customer breakdown
        count(distinct customer_unique_id) as total_active_customers,
        count(distinct case when customer_order_sequence > 1 then customer_unique_id end) as repeat_customers,

        -- Revenue breakdown
        sum(total_order_amount) as total_revenue,
        sum(case when customer_order_sequence > 1 then total_order_amount else 0 end) as repeat_revenue

    from sequenced_orders
    group by 
        sales_year_month, 
        month_start_date
),

final as (
    select
        sales_year_month,
        month_start_date,

        total_orders,
        first_time_orders,
        repeat_orders,

        total_active_customers,
        repeat_customers,

        round(total_revenue, 2) as total_revenue,
        round(repeat_revenue, 2) as repeat_revenue,

        -- Repeat Order Share %
        round(
            case 
                when total_orders > 0 
                then (repeat_orders::float / total_orders) * 100 
                else 0 
            end, 
            2
        ) as repeat_order_percentage,

        -- Repeat Revenue Share %
        round(
            case 
                when total_revenue > 0 
                then (repeat_revenue / total_revenue) * 100 
                else 0 
            end, 
            2
        ) as repeat_revenue_percentage

    from monthly_summary
    order by month_start_date asc
)

select * from final
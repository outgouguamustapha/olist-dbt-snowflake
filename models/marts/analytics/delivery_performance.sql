with orders as (
    select
        order_id,
        customer_unique_id,
        order_purchase_at,
        order_delivered_customer_at,
        order_estimated_delivery_at,
        actual_delivery_days,
        estimated_delivery_days,
        delivery_delay_days,
        delivery_lead_time_status,
        highest_review_score
    from {{ ref('fct_orders') }}
    where order_status = 'delivered'
      and order_delivered_customer_at is not null
),

customers as (
    select
        customer_unique_id,
        customer_state
    from {{ ref('dim_customers') }}
),

orders_with_geo as (
    select
        o.order_id,
        c.customer_state,
        to_char(o.order_purchase_at, 'YYYY-MM') as sales_year_month,
        date_trunc('month', o.order_purchase_at)::date as month_start_date,
        o.actual_delivery_days,
        o.estimated_delivery_days,
        o.delivery_delay_days,
        o.delivery_lead_time_status,
        o.highest_review_score
    from orders o
    left join customers c
        on o.customer_unique_id = c.customer_unique_id
),

state_monthly_aggregations as (
    select
        sales_year_month,
        month_start_date,
        coalesce(customer_state, 'Unknown') as customer_state,

        -- Order Volume
        count(order_id) as total_delivered_orders,

        -- On-time vs Delayed Counts
        count(case when delivery_lead_time_status = 'On Time' then order_id end) as on_time_deliveries,
        count(case when delivery_lead_time_status = 'Delayed' then order_id end) as delayed_deliveries,

        -- Lead Time Averages
        avg(actual_delivery_days) as avg_actual_delivery_days,
        avg(estimated_delivery_days) as avg_estimated_delivery_days,
        avg(case when delivery_lead_time_status = 'Delayed' then delivery_delay_days end) as avg_delay_days_when_late,

        -- Customer Satisfaction
        avg(highest_review_score) as avg_review_score

    from orders_with_geo
    group by
        sales_year_month,
        month_start_date,
        coalesce(customer_state, 'Unknown')
),

final as (
    select
        sales_year_month,
        month_start_date,
        customer_state,
        total_delivered_orders,
        on_time_deliveries,
        delayed_deliveries,

        -- Rounded Lead Time Metrics
        round(avg_actual_delivery_days, 1) as avg_actual_delivery_days,
        round(avg_estimated_delivery_days, 1) as avg_estimated_delivery_days,
        round(coalesce(avg_delay_days_when_late, 0), 1) as avg_delay_days_when_late,

        -- On-Time SLA Fulfillment Rate %
        round(
            case 
                when total_delivered_orders > 0 
                then (on_time_deliveries::float / total_delivered_orders) * 100 
                else 0 
            end, 
            2
        ) as on_time_delivery_rate_pct,

        round(avg_review_score, 2) as avg_review_score

    from state_monthly_aggregations
    order by month_start_date asc, customer_state asc
)

select * from final
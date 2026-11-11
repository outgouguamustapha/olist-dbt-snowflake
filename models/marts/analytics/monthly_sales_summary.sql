with orders as (
    -- Pull from our verified order fact table
    select * from {{ ref('fct_orders') }}
),

monthly_aggregations as (
    select
        -- 1. Date Grouping (Year-Month)
        to_char(order_purchase_at, 'YYYY-MM') as sales_year_month,
        date_trunc('month', order_purchase_at)::date as month_start_date,

        -- 2. Order Volume Metrics
        count(order_id) as total_orders,
        count(case when order_status = 'delivered' then order_id end) as delivered_orders,
        count(case when order_status = 'canceled' then order_id end) as canceled_orders,

        -- 3. Customer Reach
        count(distinct customer_unique_id) as unique_customers,

        -- 4. Financial Totals (Gross Merchandise Value & Shipping)
        sum(case when order_status != 'canceled' then items_gross_amount else 0 end) as total_merchandise_sales,
        sum(case when order_status != 'canceled' then freight_amount else 0 end) as total_freight_collected,
        sum(case when order_status != 'canceled' then total_order_amount else 0 end) as gross_revenue,

        -- 5. Physical Products Sold
        sum(case when order_status != 'canceled' then total_items_count else 0 end) as total_items_sold

    from orders
    group by 
        to_char(order_purchase_at, 'YYYY-MM'),
        date_trunc('month', order_purchase_at)::date
),

final as (
    select
        sales_year_month,
        month_start_date,

        -- Order & Volume KPIs
        total_orders,
        delivered_orders,
        canceled_orders,
        unique_customers,
        total_items_sold,

        -- Revenue Totals
        round(total_merchandise_sales, 2) as total_merchandise_sales,
        round(total_freight_collected, 2) as total_freight_collected,
        round(gross_revenue, 2) as gross_revenue,

        -- Simple E-Commerce Health Averages
        -- Average Order Value (AOV) = Revenue / Non-canceled Orders
        round(
            case 
                when (total_orders - canceled_orders) > 0 
                then total_merchandise_sales / (total_orders - canceled_orders)
                else 0 
            end, 
            2
        ) as average_order_value,

        -- Average Items Per Order (Basket Size)
        round(
            case 
                when (total_orders - canceled_orders) > 0 
                then total_items_sold / (total_orders - canceled_orders)
                else 0 
            end, 
            2
        ) as average_items_per_order

    from monthly_aggregations
    order by month_start_date asc
)

select * from final
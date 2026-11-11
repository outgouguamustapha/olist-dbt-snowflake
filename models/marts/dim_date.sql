with date_spine as (
    -- Generates daily calendar spine covering Olist's operating & future fulfillment range (2016 to 2020)
    select 
        dateadd(day, row_number() over (order by null) - 1, '2016-01-01'::date) as calendar_date
    from table(generator(rowcount => 2000))
    qualify calendar_date <= '2021-01-01'::date
),

final as (
    select
        -- Primary Key (integer surrogate key: YYYYMMDD)
        cast(to_char(calendar_date, 'YYYYMMDD') as integer) as date_key,
        
        calendar_date,
        
        -- Calendar attributes
        extract(year from calendar_date) as year,
        extract(quarter from calendar_date) as quarter,
        extract(month from calendar_date) as month,
        to_char(calendar_date, 'MMMM') as month_name,
        to_char(calendar_date, 'MON') as month_short_name,
        extract(week from calendar_date) as week_of_year,
        extract(day from calendar_date) as day_of_month,
        extract(dayofweek from calendar_date) as day_of_week,
        to_char(calendar_date, 'DY') as day_of_week_short,
        to_char(calendar_date, 'Day') as day_of_week_name,
        
        -- Business logic flags
        case 
            when extract(dayofweek from calendar_date) in (0, 6) then true 
            else false 
        end as is_weekend,
        
        -- Formatted periods for dashboard labels
        to_char(calendar_date, 'YYYY-MM') as year_month,
        concat('Q', extract(quarter from calendar_date), '-', extract(year from calendar_date)) as quarter_year

    from date_spine
)

select * from final
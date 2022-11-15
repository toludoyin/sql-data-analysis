-- 1. What day of the week is used for each week_date value?
select to_char(week_dates, 'day') as day_of_week
from data_mart.clean_weekly_sales;

-- 2. What range of week numbers are missing from the dataset?
with date_serie as (
    select
        extract('week' from (generate_series(first_date, last_date, '1 week'))) as date_seriess
    from (
        select
            min(week_dates) as first_date,
            max(week_dates) as last_date
        from data_mart.clean_weekly_sales
    ) as min_max_date
)
select date_seriess
from  date_serie
where date_series not in (
    select week_number
    from data_mart.clean_weekly_sales
    )
order by 1;

-- 3. How many total transactions were there for each year in the dataset?
select
    calender_year, sum(transactions) as total_txn
from data_mart.clean_weekly_sales
group by 1;

-- 4. What is the total sales for each region for each month?
select
    month_number, region, sum(sales) as total_txn
from data_mart.clean_weekly_sales
group by 1,2
order by 1;

-- 5. What is the total count of transactions for each platform
select
    platform, count(transactions) as total_txn_count
from data_mart.clean_weekly_sales
group by 1;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
-- 7. What is the percentage of sales by demographic for each year in the dataset?
-- 8. Which age_band and demographic values contribute the most to Retail sales?
-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?


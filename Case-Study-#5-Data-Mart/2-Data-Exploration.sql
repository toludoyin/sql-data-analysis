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
select
    month_, round((retail_sales/total::numeric),2) as retail_pertcg,
    round((shopify_sales/total::numeric),2) as shopify_pertcg, total
from (
    select
        date_trunc('month', week_dates) as month_,
        sum(case when platform = 'Retail' then sales end) as retail_sales,
        sum(case when platform = 'Shopify' then sales end) as shopify_sales,
        sum(sales) as total
    from data_mart.clean_weekly_sales
    group by 1
    order by 1
) as agg_pertcg
order by 1;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
select
   year_, round((couples_sales/total::numeric),2) as couples_pertcg,
    round((unknown_sales/total::numeric),2) as unknown_pertcg,
    round((families_sales/total::numeric),2) as families_pertcg
from (
    select
        date_trunc('year', week_dates) as year_,
        sum(case when demographic = 'Couples' then sales end) as couples_sales,
        sum(case when demographic = 'unknown' then sales end) as unknown_sales,
        sum(case when demographic = 'Families' then sales end) as families_sales,
        sum(sales) as total
    from data_mart.clean_weekly_sales
    group by 1
    order by 1
) as agg_pertcg
order by 1;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
select
    concat(demographic , '_', age_band) as dem_age, sum(sales) as total,
    rank() over(order by sum(sales) desc) as rank_no
from data_mart.clean_weekly_sales
where platform = 'Retail'
group by 1 order by 2 desc;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- Thought: using the avg_transaction column to get avgerage txn size will be a repeatition of average calculation
select
    year_, retail_sales/retail_txn as retail_pertcg,
    shopify_sales/shopify_txn as shopify_pertcg
from (
    select
        date_trunc('year', week_dates) as year_,
        sum(case when platform = 'Retail' then sales end) as retail_sales,
        sum(case when platform = 'Retail' then transactions end) as retail_txn,
        sum(case when platform = 'Shopify' then sales end) as shopify_sales,
        sum(case when platform = 'Shopify' then transactions end) as shopify_txn
    from data_mart.clean_weekly_sales
    group by 1--,2,sales
    order by 1
) as agg_pertcg
order by 1;
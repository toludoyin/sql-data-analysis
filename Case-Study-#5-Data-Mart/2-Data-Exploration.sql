-- 1. What day of the week is used for each week_date value?
SELECT TO_CHAR(week_dates, 'day') AS day_of_week
FROM data_mart.clean_weekly_sales;

-- 2. What range of week numbers are missing from the dataset?
with date_serie AS (
    SELECT
        extract('week' FROM (GENERATE_SERIES(first_date, last_date, '1 week'))) AS date_seriess
    FROM (
        SELECT
            MIN(week_dates) AS first_date,
            MAX(week_dates) AS last_date
        FROM data_mart.clean_weekly_sales
    ) AS min_max_date
)
SELECT date_seriess
FROM date_serie
WHERE date_series NOT IN (
    SELECT week_number
    FROM data_mart.clean_weekly_sales
)
ORDER BY 1;

-- 3. How many total transactions were there for each year in the dataset?
SELECT
    calender_year, SUM(transactions) AS total_txn
FROM data_mart.clean_weekly_sales
group by 1;

-- 4. What is the total sales for each region for each month?
SELECT
    month_number, region, SUM(sales) AS total_txn
FROM data_mart.clean_weekly_sales
GROUP BY 1,2
ORDER BY 1;

-- 5. What is the total count of transactions for each platform
SELECT
    platform, COUNT(transactions) AS total_txn_count
FROM data_mart.clean_weekly_sales
GROUP BY 1;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
SELECT
    month_, ROUND((retail_sales/total::NUMERIC),2) AS retail_pertcg,
    ROUND((shopify_sales/total::NUMERIC),2) AS shopify_pertcg, total
FROM (
    SELECT
        date_trunc('month', week_dates) AS month_,
        SUM(CASE WHEN platform = 'Retail' THEN sales END) AS retail_sales,
        SUM(CASE WHEN platform = 'Shopify' THEN sales END) AS shopify_sales,
        SUM(sales) AS total
    FROM data_mart.clean_weekly_sales
    GROUP BY 1
) AS agg_pertcg
ORDER BY 1;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
SELECT
   year_, ROUND((couples_sales/total::NUMERIC),2) AS couples_pertcg,
    ROUND((unknown_sales/total::NUMERIC),2) AS unknown_pertcg,
    ROUND((families_sales/total::NUMERIC),2) AS families_pertcg
FROM (
    SELECT
        DATE_TRUNC('year', week_dates) AS year_,
        SUM(CASE WHEN demographic = 'Couples' THEN sales END) AS couples_sales,
        SUM(CASE WHEN demographic = 'unknown' THEN sales END) AS unknown_sales,
        SUM(CASE WHEN demographic = 'Families' THEN sales END) AS families_sales,
        SUM(sales) AS total
    FROM data_mart.clean_weekly_sales
    GROUP BY 1
) AS agg_pertcg
ORDER BY 1;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT
    CONCAT(demographic , '_', age_band) AS dem_age,
    SUM(sales) AS total,
    RANK() OVER( ORDER BY SUM(sales) DESC) AS rank_no
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY 1 ORDER BY 2 DESC;

-- 9. Can we use the avg_transaction column to find the average transaction
-- size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- Thought: using the avg_transaction column to get avgerage txn size will be a repeatition of average calculation
SELECT
    year_, retail_sales/retail_txn AS retail_pertcg,
    shopify_sales/shopify_txn AS shopify_pertcg
FROM (
    SELECT
        DATE_TRUNC('YEAR', week_dates) AS year_,
        SUM(CASE WHEN platform = 'Retail' THEN sales END) AS retail_sales,
        SUM(CASE WHEN platform = 'Retail' THEN transactions END) AS retail_txn,
        SUM(CASE WHEN platform = 'Shopify' THEN sales END) AS shopify_sales,
        SUM(CASE WHEN platform = 'Shopify' THEN transactions END) AS shopify_txn
    FROM data_mart.clean_weekly_sales
    GROUP BY 1--,2,sales
) AS agg_pertcg
ORDER BY 1;
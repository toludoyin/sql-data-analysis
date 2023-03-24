/**
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

Convert the week_date to a DATE format

Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

Add a month_number with the calendar month for each week_date value as the 3rd column

Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees
Add a new demographic column using the following mapping for the first letter in the segment values:
segment	demographic
C	Couples
F	Families
Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
**/

DROP TABLE IF EXISTS data_mart.clean_weekly_sales;
CREATE TABLE data_mart.clean_weekly_sales AS (
    SELECT
        week_dates,
        EXTRACT('week' FROM week_dates::DATE) AS week_number,
        EXTRACT('month' FROM week_dates::DATE) AS month_number,
        EXTRACT('year' FROM week_dates::DATE) AS calender_year,
        CASE WHEN (segment) LIKE '%1' THEN 'Young Adults'
             WHEN (segment) LIKE '%2' THEN 'Middle Aged'
             WHEN (segment) LIKE '%3' OR (segment) LIKE '%4' THEN 'Retirees'
            ELSE segment END AS age_band,
        CASE WHEN (segment) LIKE 'C%' THEN 'Couples'
             WHEN (segment) LIKE 'F%' THEN 'Families'
             ELSE segment END AS demographic,
        region, platform, customer_type, transactions, sales,
        ROUND(AVG(sales/transactions),2) AS avg_transaction
    FROM (
        SELECT
            TO_DATE(week_date,'DD/MM/YY') AS week_dates, region, platform,
            customer_type, transactions, sales,
            CASE WHEN (segment) IN ('null', NULL) THEN 'unknown'
            ELSE segment END AS segment
        FROM data_mart.weekly_sales
    )week_table
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11);

SELECT * FROM data_mart.clean_weekly_sales;
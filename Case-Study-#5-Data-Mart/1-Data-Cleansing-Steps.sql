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
    select
        week_dates,
        extract('week' from week_dates::date) as week_number,
        extract('month' from week_dates::date) as month_number,
        extract('year' from week_dates::date) as calender_year,
        case when (segment) like '%1' then 'Young Adults'
             when (segment) like '%2' then 'Middle Aged'
             when (segment) like '%3' or (segment) like '%4' then 'Retirees'
            else segment end as age_band,
        case when (segment) like 'C%' then 'Couples'
             when (segment) like 'F%' then 'Families'
             else segment end as demographic,
        region, platform, customer_type, transactions, sales,
        round(avg(sales/transactions),2) as avg_transaction
    from (
        select
            to_date(week_date,'DD/MM/YY') as week_dates, region, platform,
            customer_type, transactions, sales,
            case when (segment) in ('null', NULL) then 'unknown'
            else segment end as segment
        from data_mart.weekly_sales
    )week_table
    group by 1,2,3,4,5,6,7,8,9,10,11);

select * from data_mart.clean_weekly_sales;
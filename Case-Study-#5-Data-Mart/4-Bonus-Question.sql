/**
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
**/
SELECT metrics, ROUND(AVG(pertcg),2) AS avg_sales
FROM (
    SELECT
        'region' AS metrics, initcap(region) AS value, before_effect,
        after_effect, after_effect - before_effect AS change,
        ROUND(((after_effect-before_effect)/before_effect::NUMERIC)*100,2) AS pertcg, '2018' AS year_
    FROM (
        SELECT
            region, SUM(sales) FILTER(WHERE week_dates < '2018-06-15'::DATE) AS before_effect,
            SUM(sales) FILTER(WHERE week_dates >= '2018-06-15'::DATE) AS after_effect
        FROM (
		    SELECT week_dates, sales, region
		    FROM data_mart.clean_weekly_sales
            WHERE week_dates BETWEEN '2018-06-15'::DATE - INTERVAL '12 week'
            AND '2018-06-15'::DATE + INTERVAL '11 week'
            ORDER BY 1
	    ) delta_weeks
        GROUP BY 1
    ) AS before_after

    UNION ALL

    SELECT
        'platform' AS metrics, initcap(platform) AS value, before_effect,
        after_effect, after_effect - before_effect AS change,
        ROUND(((after_effect - before_effect)/before_effect::NUMERIC)*100,2) AS pertcg, '2019' AS year_
    FROM (
        SELECT
            platform, SUM(sales) FILTER(WHERE week_dates < '2019-06-15'::DATE) AS before_effect,
            SUM(sales) FILTER(WHERE week_dates >= '2019-06-15'::DATE) AS after_effect
        FROM (
            SELECT week_dates, sales, platform
            FROM data_mart.clean_weekly_sales
            WHERE week_dates BETWEEN '2019-06-15'::DATE - INTERVAL '12 week'
            AND '2019-06-15'::DATE + INTERVAL '11 week'
            ORDER BY 1
        ) delta_weeks
        GROUP BY 1
    ) AS before_after

    UNION ALL

    SELECT
        'age_band' AS metrics, initcap(age_band) AS value,
        before_effect, after_effect, after_effect - before_effect AS change,
        ROUND(((after_effect-before_effect)/before_effect::NUMERIC)*100,2) AS pertcg, '2020' AS year_
    FROM (
        SELECT
            age_band, SUM(sales) FILTER(WHERE week_dates < '2020-06-15'::DATE) AS before_effect,
            SUM(sales) FILTER(WHERE week_dates >= '2020-06-15'::DATE) AS after_effect
        FROM (
            SELECT week_dates, sales, age_band
            FROM data_mart.clean_weekly_sales
            WHERE week_dates BETWEEN '2020-06-15'::DATE - INTERVAL '12 week'
            AND '2020-06-15'::DATE + INTERVAL '11 week'
            ORDER BY 1
        ) delta_weeks
        GROUP BY 1
    ) AS before_after

    UNION ALL

    SELECT
        'demographic' AS metrics, INITCAP(demographic) AS value,
        before_effect, after_effect, after_effect - before_effect AS change,
        ROUND(((after_effect - before_effect)/before_effect::NUMERIC)*100,2) AS pertcg, '2020' AS year_
    FROM (
        SELECT
            demographic, SUM(sales) FILTER(WHERE week_dates < '2020-06-15'::DATE) AS before_effect,
            SUM(sales) FILTER(WHERE week_dates >= '2020-06-15'::DATE) AS after_effect
        FROM (
            SELECT week_dates, sales, demographic
            FROM data_mart.clean_weekly_sales
            WHERE week_dates BETWEEN '2020-06-15'::DATE - INTERVAL '12 week'
            AND '2020-06-15'::DATE + INTERVAL '11 week'
            ORDER BY 1
        ) delta_weeks
        GROUP BY 1
    ) AS before_after

    UNION ALL

    SELECT
        'customer_type' AS metrics,
        INITCAP(customer_type) AS value,
        before_effect, after_effect, after_effect - before_effect AS change,
        ROUND(((after_effect - before_effect) / before_effect::NUMERIC)*100, 2) AS pertcg, '2020' AS year_
    FROM (
        SELECT
            customer_type, SUM(sales) FILTER(WHERE week_dates < '2020-06-15'::DATE) AS before_effect,
            SUM(sales) FILTER(WHERE week_dates >= '2020-06-15'::DATE) AS after_effect
        FROM (
            SELECT week_dates, sales, customer_type
            FROM data_mart.clean_weekly_sales
            WHERE week_dates BETWEEN '2020-06-15'::DATE - INTERVAL '12 week'
            AND '2020-06-15'::DATE + INTERVAL'11 week'
            ORDER BY 1
        ) delta_weeks
        GROUP BY 1
    ) AS before_after
) AS tmp
GROUP BY 1
ORDER BY 2

/**
For the 2020, 12 week before and after period, region and platform have the highest negative sales metric performance impact.
**/
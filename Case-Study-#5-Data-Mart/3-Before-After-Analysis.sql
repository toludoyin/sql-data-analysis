/*
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
*/

-- 1.
SELECT
    before_effect, after_effect, after_effect - before_effect AS change,
    ROUND(((after_effect - before_effect) / before_effect::NUMERIC)*100,2) AS pertcg
FROM (
    SELECT
        SUM(sales) FILTER (WHERE week_dates < '2020-06-15'::DATE) AS before_effect,
        SUM(sales) FILTER (WHERE week_dates >= '2020-06-15'::DATE) AS after_effect
	FROM (
		SELECT week_dates, sales
		FROM data_mart.clean_weekly_sales
        WHERE week_dates BETWEEN '2020-06-15'::DATE - INTERVAL '4 week'
        AND '2020-06-15'::DATE + INTERVAL '3 week'
        ORDER BY 1
	) delta_weeks
) AS before_after;

-- 2.
SELECT
    before_effect, after_effect, after_effect - before_effect AS change,
    ROUND(((after_effect - before_effect) / before_effect::NUMERIC)*100,2) AS pertcg
FROM (
    SELECT
        SUM(sales) FILTER (WHERE week_dates < '2020-06-15'::DATE) AS before_effect,
        SUM(sales) FILTER (WHERE week_dates >= '2020-06-15'::DATE) AS after_effect
	FROM (
		SELECT week_dates, sales
        FROM data_mart.clean_weekly_sales
        WHERE week_dates BETWEEN '2020-06-15'::DATE - INTERVAL '12 week'
        AND '2020-06-15'::DATE + INTERVAL '11 week'
        ORDER BY 1
	) delta_weeks
) as before_after;

-- 3. for 4 weeks before and after
SELECT
    before_effect, after_effect, after_effect - before_effect AS change,
    ROUND(((after_effect - before_effect) / before_effect::NUMERIC)*100,2) AS pertcg, '2018' AS year_
FROM (
	SELECT
        SUM(sales) FILTER (WHERE week_dates < '2018-06-15'::DATE) AS before_effect,
        SUM(sales) FILTER (WHERE week_dates >= '2018-06-15'::DATE) AS after_effect
	FROM (
		SELECT week_dates, sales
		FROM data_mart.clean_weekly_sales
        WHERE week_dates BETWEEN '2018-06-15'::DATE - INTERVAL '4 week'
        AND '2018-06-15'::DATE + INTERVAL '3 week'
        ORDER BY 1
	) delta_weeks
) AS before_after

UNION ALL

SELECT
    before_effect, after_effect, after_effect - before_effect AS change,
    ROUND(((after_effect - before_effect) / before_effect::NUMERIC)*100,2) AS pertcg, '2019' AS year_
FROM (
	SELECT
        SUM(sales) FILTER (WHERE week_dates < '2019-06-15'::DATE) AS before_effect,
        SUM(sales) FILTER (WHERE week_dates >= '2019-06-15'::DATE) AS after_effect
	FROM (
		SELECT week_dates, sales
		FROM data_mart.clean_weekly_sales
        WHERE week_dates BETWEEN '2019-06-15'::DATE - INTERVAL '4 week'
        AND '2019-06-15'::DATE + INTERVAL '3 week'
        ORDER BY 1
	) delta_weeks
) AS before_after

UNION ALL

SELECT
    before_effect, after_effect, after_effect - before_effect AS change,
    ROUND(((after_effect - before_effect) / before_effect::NUMERIC)*100,2) AS pertcg, '2020' AS year_
FROM (
	SELECT
        SUM(sales) FILTER (WHERE week_dates < '2020-06-15'::DATE) AS before_effect,
        SUM(sales) FILTER (WHERE week_dates >= '2020-06-15'::DATE) AS after_effect
	FROM (
		SELECT week_dates, sales
		FROM data_mart.clean_weekly_sales
        WHERE week_dates BETWEEN '2020-06-15'::DATE - INTERVAL '4 week'
        AND '2020-06-15'::DATE + INTERVAL '3 week'
        ORDER BY 1
	) delta_weeks
) AS before_after;
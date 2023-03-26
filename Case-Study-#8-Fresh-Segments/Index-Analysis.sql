-- What is the top 10 interests by the average composition for each month?
WITH avg_composition AS(
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value)::NUMERIC,2) AS avg_composition,
        RANK() OVER(PARTITION BY month_year ORDER BY ROUND((composition / index_value)::NUMERIC,2) DESC) AS rank_composition
    FROM fresh_segments.interest_metrics ime
    JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
    WHERE interest_id IS NOT NULL
)
SELECT * FROM avg_composition
WHERE rank_composition <=10;

-- For all of these top 10 interests - which interest appears the most often?
WITH avg_composition AS(
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value)::NUMERIC,2) AS avg_composition,
        RANK() OVER(PARTITION BY month_year ORDER BY ROUND((composition / index_value)::NUMERIC,2) DESC) AS rank_composition
FROM fresh_segments.interest_metrics ime
JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
WHERE interest_id IS NOT NULL
)
SELECT
    interest_name,
    COUNT(interest_name) AS appear_often
FROM avg_composition
WHERE rank_composition <=10
GROUP BY 1
ORDER BY 2 DESC;

-- What is the average of the average composition for the top 10 interests for each month?
WITH avg_composition AS(
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value)::NUMERIC,2) AS avg_composition,
        RANK() OVER(PARTITION BY month_year ORDER BY ROUND((composition / index_value)::NUMERIC,2) DESC) AS rank_composition
    FROM fresh_segments.interest_metrics ime
    JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
    WHERE interest_id IS NOT NULL
)
SELECT
    month_year,
    ROUND(AVG(avg_composition),2) AS avg_avg_composition
FROM avg_composition
WHERE rank_composition <=10
GROUP BY 1;

-- What is the 3 month rolling average of the max average composition value from September 2018 to August 2019
-- and include the previous top ranking interests in the same output shown below.
WITH avg_composition AS(
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value)::NUMERIC,2) AS avg_composition,
        RANK() OVER(PARTITION BY month_year ORDER BY ROUND((composition / index_value)::NUMERIC,2) DESC) AS rank_composition
    FROM fresh_segments.interest_metrics ime
    JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
    WHERE interest_id IS NOT NULL
),
moving_avg AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        avg_composition AS max_index_composition,
        ROUND(AVG(avg_composition) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS "3_month_moving_avg"
    FROM avg_composition
    WHERE rank_composition = 1
),
previous_rank AS (
    SELECT
        month_year,
        interest_name,
        max_index_composition,
        "3_month_moving_avg",
        LAG(interest_name,1) OVER(ORDER BY month_year) interest_name1,
        LAG(interest_name,2) OVER(ORDER BY month_year) interest_name2,
        LAG(max_index_composition,1) OVER(ORDER BY month_year) max_index1,
        LAG(max_index_composition,2) OVER(ORDER BY month_year) max_index2
    FROM moving_avg ra
)
SELECT
    month_year,
    interest_name,
    max_index_composition,
    "3_month_moving_avg",
    interest_name1||':'|| max_index1 AS "1_month_ago",
    interest_name2||':'|| max_index2 AS "2_month_ago"
FROM  previous_rank
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';

/*
Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?

ANSWER:
some reason a change might occur are seasonal factor, competitors/customers preference, service quality among others.
*/ 
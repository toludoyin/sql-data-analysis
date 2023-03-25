-- Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the
--largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
WITH filter_data AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM fresh_segments.interest_metrics
    GROUP BY 1
    HAVING COUNT(DISTINCT month_year) >= 6
),
filtered_data AS (
    SELECT * FROM filter_data
    JOIN fresh_segments.interest_metrics USING(interest_id)
),
max_interest AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        composition
    FROM (
        SELECT
            fd.*, ima.*,
            RANK() OVER(PARTITION BY fd.interest_id ORDER BY composition DESC) as composition_rank
        FROM filtered_data fd
		JOIN fresh_segments.interest_map ima ON fd.interest_id::INT = ima.id
    ) AS max_compostion
    WHERE composition_rank = 1
    ORDER BY composition DESC
    LIMIT 10
),
min_interest AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        composition
    FROM (
        SELECT
            fd.*, ima.*,
            RANK() OVER(PARTITION BY fd.interest_id ORDER BY composition ASC) as composition_rank
        FROM filtered_data fd
        JOIN fresh_segments.interest_map ima ON fd.interest_id::INT = ima.id
    ) AS min_compostion
    WHERE composition_rank = 1
    ORDER BY composition
    LIMIT 10
)
SELECT * FROM min_interest;
-- SELECT * FROM max_interest;

-- Which 5 interests had the lowest average ranking value?
WITH filter_data AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM fresh_segments.interest_metrics
    GROUP BY 1
    HAVING COUNT(DISTINCT month_year) >= 6
),
filtered_data AS (
    SELECT * FROM filter_data
    JOIN fresh_segments.interest_metrics USING(interest_id)
)
SELECT
    interest_name,
    AVG(ranking)::NUMERIC(10,2) AS avg_ranking
FROM filtered_data fd
LEFT JOIN fresh_segments.interest_map ima ON fd.interest_id::INT = ima.id
WHERE interest_name IS NOT NULL
GROUP BY 1
ORDER BY 2
LIMIT 5;

-- Which 5 interests had the largest standard deviation in their percentile_ranking value?
WITH filter_data AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM fresh_segments.interest_metrics
    GROUP BY 1
    HAVING COUNT(DISTINCT month_year) >= 6
),
filtered_data AS (
    SELECT * FROM filter_data
    JOIN fresh_segments.interest_metrics USING(interest_id)
)
SELECT
    interest_name,
    ROUND(STDDEV(percentile_ranking)::NUMERIC, 2) AS std_percentile_ranking
FROM filtered_data fd
LEFT JOIN fresh_segments.interest_map ima ON fd.interest_id::INT = ima.id
WHERE interest_name IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

/* For the 5 interests found in the previous question - what was minimum and
maximum percentile_ranking values for each interest and its corresponding
year_month value? Can you describe what is happening for these 5 interests?

 ANSWER:
* range between minimum and maximum is very wide.
* notice that month_year for the maximum occurred before the minimum month_year
which means something must have changed in the product or service render for
percentile_ranking to have decline in recent time and this should be looked into for business understanding.
* both minimum and maximum of each interest
*/
WITH filter_data AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM fresh_segments.interest_metrics
    GROUP BY 1
    HAVING COUNT(DISTINCT month_year) >= 6
),
filtered_data AS (
    SELECT * FROM filter_data
    JOIN fresh_segments.interest_metrics USING(interest_id)
),
standard_dev as (   -- PREVIOUS QUESTION
    SELECT
        fd.interest_id,
        interest_name,
        ROUND(STDDEV(percentile_ranking)::NUMERIC, 2) AS std_percentile_ranking
    FROM filtered_data fd
    LEFT JOIN fresh_segments.interest_map ima ON fd.interest_id::INT = ima.id
    WHERE interest_name IS NOT NULL
    GROUP BY 1,2
    ORDER BY 3 DESC
    LIMIT 5
),
min_max_percentile AS (
    SELECT
        month_year,
        interest_name,
        percentile_ranking,
        MIN(percentile_ranking) OVER(PARTITION BY interest_id) AS min_percentile,
        MAX(percentile_ranking) OVER(PARTITION BY interest_id) AS max_percentile
    FROM standard_dev
    JOIN fresh_segments.interest_metrics USING(interest_id)
)
SELECT interest_name,
    MIN(CASE WHEN percentile_ranking = min_percentile THEN month_year END) AS min_month_year,
    MIN(CASE WHEN percentile_ranking = min_percentile THEN min_percentile END) AS min_percentile,
    MAX(CASE WHEN percentile_ranking = max_percentile THEN month_year END) AS max_month_year,
    MAX(CASE WHEN percentile_ranking = max_percentile THEN max_percentile END) AS max_percentile
FROM min_max_percentile
GROUP BY 1

/*
How would you describe our customers in this segment based off their
-- composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?

what we should avoid, which are the least rank interest of our customers are; Winter Apparel Shoppers, Fitness Activity Tracker Users, Mens Shoe Shoppers, Shoe Shoppers, Preppy Clothing Shoppers

using the average ranking value, League of Legends Video Game Fans ranks the topmost interest of the customers, therefore, there is need to invest in giving the best to the customers.

*/
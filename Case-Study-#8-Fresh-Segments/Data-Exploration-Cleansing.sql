--------------------------------
-- DATA EXPLORATION AND CLEANING
--------------------------------

--1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE
USING TO_DATE(month_year, 'MM-YYYY');

SELECT * FROM fresh_segments.interest_metrics
LIMIT 5;

--2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT
    DATE_TRUNC('MONTH', month_year) AS month_year,
    COUNT(*) AS record_count
FROM fresh_segments.interest_metrics
GROUP BY 1
ORDER BY month_year NULLS FIRST;

--3. What do you think we should do with these null values in the fresh_segments.interest_metrics
-- **Non-coding question**

--4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT
    COUNT(DISTINCT interest_id) AS num_of_interest_id
FROM fresh_segments.interest_metrics
WHERE interest_id::INT NOT IN (
    SELECT id
    FROM fresh_segments.interest_map
);

SELECT
	COUNT(id) AS num_of_interest_id
FROM fresh_segments.interest_map
WHERE id NOT IN (
    SELECT
	    DISTINCT interest_id::INT
    FROM fresh_segments.interest_metrics
    WHERE interest_id IS NOT NULL
 );

--5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT
	COUNT(*) AS total_records
FROM fresh_segments.interest_map;

--6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
SELECT
    DISTINCT ime.interest_id::INT,
    interest_name,
    interest_summary,
    created_at,
    last_modified,
    _month,
    _year,
    month_year,
    composition,
    index_value,
    ranking,
    percentile_ranking
FROM fresh_segments.interest_map AS ima
JOIN fresh_segments.interest_metrics AS ime ON ima.id = ime.interest_id::INT
WHERE interest_id = '21246'
AND month_year IS NOT NULL;

--7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
SELECT COUNT(*) AS "month_year < created_at"
FROM fresh_segments.interest_map AS ima
JOIN fresh_segments.interest_metrics AS ime ON ima.id = ime.interest_id::INT
WHERE month_year < created_at;
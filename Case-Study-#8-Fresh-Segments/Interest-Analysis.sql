--1. Which interests have been present in all month_year dates in our dataset?
WITH interest AS (
  SELECT
    id,
    interest_name,
    COUNT(interest_id) AS present_time
  FROM fresh_segments.interest_metrics ime
  LEFT JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
  GROUP BY 1,2
  HAVING COUNT(interest_id) = 14 -- we have 14 total_month record
)
SELECT interest_name FROM interest;

--2. Using this same total_months measure - calculate the cumulative percentage of
-- all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
WITH interest AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_month
  FROM fresh_segments.interest_metrics ime
  LEFT JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
  GROUP BY 1
)
SELECT
  total_month,
  COUNT(*) AS num,
  ROUND(100 * SUM(COUNT(*)) OVER(ORDER BY total_month DESC) /
  SUM(COUNT(*)) OVER(), 2) AS cummulative_pertcg
FROM interest
GROUP BY 1
ORDER BY 1 DESC;

--3. If we were to remove all interest_id values which are lower than the
-- total_months value we found in the previous question - how many total data points would we be removing?
WITH rows_removed AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_month
  FROM fresh_segments.interest_metrics ime
  LEFT JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
  GROUP BY 1
  HAVING COUNT(DISTINCT month_year) < 6
)
SELECT SUM(total_month) FROM rows_removed;

--4. Does this decision make sense to remove these data points from a business
-- perspective? Use an example where there are all 14 months present to a
-- removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

-- ANSWER: In a segment perspective, when considering target interest (like sending customise messaging) then this should make sense

--5. After removing these interests - how many unique interests are there for each month?
WITH rows_removed AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_month
  FROM fresh_segments.interest_metrics ime
  LEFT JOIN fresh_segments.interest_map ima ON ime.interest_id::INT = ima.id
  GROUP BY 1
  HAVING COUNT(DISTINCT month_year) >= 6
)
SELECT
  DATE_TRUNC('MONTH', month_year) AS months,
  COUNT(DISTINCT rr.interest_id) AS unique_interest
FROM rows_removed rr
JOIN fresh_segments.interest_metrics ime ON rr.interest_id = ime.interest_id
WHERE month_year IS NOT NULL
GROUP BY 1
ORDER BY 1;
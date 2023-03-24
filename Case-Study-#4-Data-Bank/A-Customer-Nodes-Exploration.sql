-- 1. How many unique nodes are there on the Data Bank system?
SELECT DISTINCT node_id AS num_of_nodes
FROM data_bank.customer_nodes
ORDER BY 1;

-- 2. What is the number of nodes per region?
SELECT
    region_id, region_name,
    COUNT(DISTINCT node_id) AS num_of_nodes
FROM data_bank.customer_nodes
JOIN data_bank.regions USING(region_id)
GROUP BY 1,2
ORDER BY 1;

-- 3. How many customers are allocated to each region?
SELECT
    region_id, region_name,
    COUNT(DISTINCT customer_id) AS num_of_cust
FROM data_bank.customer_nodes
JOIN data_bank.regions USING(region_id)
GROUP BY 1,2
ORDER BY 1;

-- 4. How many days on average are customers reallocated to a different node?
SELECT ROUND(AVG(end_date - start_date),1) AS avg_date
FROM (
    SELECT
        customer_id, start_date,
        CASE WHEN end_date > current_date THEN'2020-12-31'::DATE ELSE end_date END AS end_date
    FROM data_bank.customer_nodes
) AS avg_date;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH nodes AS (
    SELECT *, end_date - start_date AS node_days
    FROM (
        SELECT
            region_id, start_date,
            CASE WHEN end_date > current_date THEN '2020-12-31'::DATE ELSE end_date END AS end_date
        FROM data_bank.customer_nodes
    ) tmp
 )
SELECT
    region_id, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY node_days) AS median,
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY node_days) AS q80,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY node_days)::NUMERIC, 1) AS q95
FROM nodes
GROUP BY region_id;
-- How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transaction
FROM balanced_tree.sales;

-- What is the average unique products purchased in each transaction?
SELECT
COUNT(prod_id)/COUNT(DISTINCT txn_id) AS avg_unique_product
FROM balanced_tree.sales s;

-- What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH txn_revenue AS (
    SELECT txn_id, SUM(price * qty) AS revenue
    FROM balanced_tree.sales
    GROUP BY 1
)
SELECT
PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) AS per_25,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue) AS per_50,
PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) AS per_75
FROM txn_revenue;

-- What is the average discount value per transaction?
SELECT txn_id, AVG(discount) AS avg_discount
FROM balanced_tree.sales
GROUP BY 1;

-- What is the percentage split of all transactions for members vs non-members?
  SELECT ROUND(AVG(total_discount),2) AS avg_discount FROM (
  SELECT txn_id, SUM(price * qty * discount)/100 AS total_discount
  FROM balanced_tree.sales
  GROUP BY 1
    ) AS avg_dis;

-- What is the average revenue for member transactions and non-member transactions?
SELECT bts.member, ROUND(AVG(price * qty),2) AS avg_discount
FROM balanced_tree.sales AS bts
GROUP BY 1;
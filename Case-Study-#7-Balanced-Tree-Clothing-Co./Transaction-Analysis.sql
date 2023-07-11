-- How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transaction
FROM balanced_tree.sales;

-- What is the average unique products purchased in each transaction?
SELECT
COUNT(prod_id)/COUNT(DISTINCT txn_id) AS avg_unique_product
FROM balanced_tree.sales s

-- What are the 25th, 50th and 75th percentile values for the revenue per transaction?
-- What is the average discount value per transaction?
-- What is the percentage split of all transactions for members vs non-members?
-- What is the average revenue for member transactions and non-member transactions?
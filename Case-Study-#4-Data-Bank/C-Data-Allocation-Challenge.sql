/**
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

1. running customer balance column that includes the impact each transaction
2. customer balance at the end of each month
3. minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis?
**/

-- Option 1
WITH closing_bal AS (
    SELECT
        customer_id, txn_month,
        SUM(txn_amount) OVER(PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_bal
    FROM (
        SELECT
            customer_id, DATE_TRUNC('MONTH', txn_date) AS txn_month,
            SUM(txn_status) AS txn_amount
        FROM (
            SELECT *,
                CASE WHEN txn_type ='deposit' THEN txn_amount ELSE -1*txn_amount END AS txn_status
            FROM data_bank.customer_transactions
            ORDER BY customer_id, txn_date
        ) deposit_txn
        GROUP BY 1,2
    ) total_deposit
),
data_stores AS (
    SELECT *,
        CASE WHEN previous_month_bal < 0 THEN 0 ELSE previous_month_bal END AS data_store,
        CASE WHEN previous_month_bal IS NULL THEN NULL
        WHEN previous_month_bal =0 THEN closing_bal*100 ELSE
        ROUND(((closing_bal - (previous_month_bal)) / ABS(previous_month_bal))*100) END AS growth_rate,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY txn_month DESC) AS bal_index
    FROM (
        SELECT *,
            LAG(closing_bal) OVER(PARTITION BY customer_id ORDER BY txn_month) AS previous_month_bal
        FROM closing_bal
        ) previous_bal
)
SELECT txn_month, SUM(data_store) AS data_storage
FROM data_stores
GROUP BY 1
ORDER BY 1;

-- Option 2
WITH txn_deposit AS (
    SELECT *,
        CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END AS txn_group
    FROM data_bank.customer_transactions
),
date_series AS (
    SELECT
        customer_id, generate_series(first_date, last_date, '1 day') AS date_series
    FROM (
        SELECT
            customer_id, MAX(txn_date) AS last_date,
            MIN(txn_date) AS first_date
        FROM txn_deposit
        GROUP BY 1
    ) min_max_series
),
customer_balance AS (
    SELECT *,
        SUM(txn_group) OVER(PARTITION BY customer_id ORDER BY date_series) AS txn_sum
    FROM (
        SELECT
            ds.customer_id, date_series, txn_group,
            COUNT(txn_group) OVER(PARTITION BY ds.customer_id ORDER BY date_series) AS txn_count
        FROM date_series ds
        LEFT JOIN txn_deposit td ON ds.customer_id = td.customer_id
        AND ds.date_series = td.txn_date
        ORDER BY ds.customer_id, date_series
    ) AS cust_bal_count
),
customer_data AS (
    SELECT
        customer_id, date_series, CASE WHEN txn_row_no < 30 THEN NULL
        WHEN avg_last_30_days < 0 THEN 0 ELSE avg_last_30_days END AS data_store
    FROM (
        SELECT *,
            AVG(txn_sum) OVER(PARTITION BY customer_id ORDER BY date_series ROWS BETWEEN 30 PRECEDING CURRENT ROW) AS avg_last_30_days,
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY date_series) AS txn_row_no
        FROM customer_balance
        ORDER BY 1
    ) AS last_30_days
)
SELECT
    month, ROUND(SUM(data_allocation),1) AS total_allocation
FROM (
    SELECT
        customer_id,
        DATE_TRUNC('MONTH', date_series) AS month,
        MAX(data_store) AS data_allocation
    FROM customer_data
    GROUP BY customer_id, month
) AS allocated_data
GROUP BY 1
ORDER BY 1;

-- Option 3
WITH txn_deposit AS (
    SELECT *, CASE WHEN txn_type = 'deposit'
    THEN txn_amount ELSE -1 * txn_amount END AS txn_group
    FROM data_bank.customer_transactions
),
date_series AS (
    SELECT
        customer_id, generate_series(first_date, last_date, '1 day') AS date_series
    FROM (
        SELECT
            customer_id, MAX(txn_date) AS last_date,
            MIN(txn_date) AS first_date
        FROM txn_deposit
        GROUP BY 1
    ) min_max_series
),
customer_balance AS (
    SELECT *, SUM(txn_group) OVER(PARTITION BY customer_id ORDER BY date_series) AS txn_sum
    FROM (
        SELECT ds.customer_id, date_series, txn_group
        FROM date_series ds
        LEFT JOIN txn_deposit td ON ds.customer_id = td.customer_id
        AND ds.date_series = td.txn_date
        ORDER BY ds.customer_id, date_series
    ) AS cust_bal_count
),
customer_data AS (
    SELECT
        customer_id, date_series,
        CASE WHEN txn_sum < 0 THEN 0 ELSE txn_sum END AS data_store
    FROM customer_balance
)
SELECT
    month, ROUND(SUM(data_allocation),1) AS total_allocation
FROM (
    SELECT
        customer_id,
        DATE_TRUNC('MONTH', date_series) AS month,
        MAX(data_store) AS data_allocation
    FROM customer_data
    GROUP BY customer_id, month
) AS allocated_data
GROUP BY 1
ORDER BY 1;
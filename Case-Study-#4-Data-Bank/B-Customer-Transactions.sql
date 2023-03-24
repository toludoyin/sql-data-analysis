-- 1. What is the unique count and total amount for each transaction type?
SELECT
    txn_type,
    COUNT(*) AS unique_count, SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
group by 1;

-- 2. What is the average total historical deposit counts and amounts for all customers?
SELECT
    ROUND(AVG(unique_count),1) AS avg_count,
    ROUND(AVG(total_amount),1) AS avg_total_amount
FROM (
    SELECT
        customer_id, COUNT(*) AS unique_count, SUM(txn_amount) AS total_amount
    FROM data_bank.customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY 1
) AS tmp;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
SELECT
    txn_month,
    COUNT(CASE WHEN deposit_count > 1 AND (purchase_count > 1 OR withdrawal_count > 1) THEN customer_id END) AS num_of_cust
FROM (
    SELECT
        DATE_TRUNC('MONTH', txn_date) AS txn_month,
        customer_id,
        COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
        COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
        COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
    FROM data_bank.customer_transactions
    GROUP BY 1,2
    ORDER BY 1
) AS tmp
GROUP BY 1;

-- 4. What is the closing balance for each customer at the end of the month?
SELECT
    customer_id, txn_month,
    SUM(txn_amount) OVER(PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_bal
FROM (
    SELECT
        customer_id, DATE_TRUNC('MONTH', txn_date) AS txn_month,
        SUM(txn_status) AS txn_amount
    FROM (
        SELECT *,
            CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -1 * txn_amount END AS txn_status
        FROM data_bank.customer_transactions
        ORDER BY customer_id, txn_date
    ) tmp
    GROUP BY 1,2
) closing_bal;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH closing_bal AS (
    SELECT
        customer_id, txn_month,
        SUM(txn_amount) OVER(PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_bal
    FROM (
        SELECT customer_id, DATE_TRUNC('MONTH', txn_date) AS txn_month, SUM(txn_status) AS txn_amount
        FROM (
            SELECT *,
                CASE WHEN txn_type ='deposit' THEN txn_amount ELSE -1*txn_amount END AS txn_status
            FROM data_bank.customer_transactions
            ORDER BY customer_id, txn_date
        ) deposit_txn
        GROUP BY 1,2
    ) total_deposit
),
growth_rate AS (
    SELECT *,
        CASE WHEN previous_month_bal IS NULL THEN NULL WHEN previous_month_bal = 0 THEN closing_bal*100 ELSE
        ROUND(((closing_bal - (previous_month_bal))/ABS(previous_month_bal))*100) END AS growth_rate,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY txn_month DESC) AS bal_index
    FROM (
        SELECT *,
            LAG(closing_bal) OVER(PARTITION BY customer_id ORDER BY txn_month) AS previous_month_bal
        FROM closing_bal
    ) previous_bal
),
cust_last_bal AS (
    SELECT
        customer_id, closing_bal, growth_rate,
        CASE WHEN growth_rate > 5 THEN 1 ELSE 0 END AS growth_rate_check
    FROM growth_rate
    WHERE bal_index = 1
)
SELECT
    ROUND((SUM(growth_rate_check) / COUNT(*)::NUMERIC) * 100, 1) AS user_increase_bal_by_5
FROM cust_last_bal;
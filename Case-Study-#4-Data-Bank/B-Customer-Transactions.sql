-- 1. What is the unique count and total amount for each transaction type?
select txn_type, count(*) as unique_count, sum(txn_amount) as total_amount
from data_bank.customer_transactions
group by 1;

-- 2. What is the average total historical deposit counts and amounts for all customers?
select round(avg(unique_count),1) as avg_count, round(avg(total_amount),1) as avg_total_amount
from (
  select
customer_id,count(*) as unique_count, sum(txn_amount) as total_amount
from data_bank.customer_transactions
where txn_type = 'deposit'
group by 1
  ) as tmp;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
select txn_month,
count(case when deposit_count>1 and (purchase_count>1 or withdrawal_count>1) then customer_id end) as num_of_cust
from (
    select
    date_trunc('month', txn_date) as txn_month, customer_id,
    count(case when txn_type = 'deposit' then 1 end) as deposit_count,
    count(case when txn_type = 'purchase' then 1 end) as purchase_count,
    count(case when txn_type = 'withdrawal' then 1 end) as withdrawal_count
    from data_bank.customer_transactions
    group by 1,2
    order by 1
) as tmp
group by 1;

-- 4. What is the closing balance for each customer at the end of the month?

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
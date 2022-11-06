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
select customer_id, txn_month,
sum(txn_amount) over(partition by customer_id order by txn_month rows between unbounded preceding and current row) as closing_bal
from (
    select customer_id, date_trunc('month', txn_date) as txn_month,
    sum(txn_status) as txn_amount
    from (
        select *, case when txn_type ='deposit' then txn_amount else -1 * txn_amount end as txn_status
        from data_bank.customer_transactions
        order by customer_id, txn_date
    ) tmp
    group by 1,2
) closing_bal;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
with closing_bal as (
    select customer_id, txn_month,
    sum(txn_amount) over(partition by customer_id order by txn_month rows between unbounded preceding and current row) as closing_bal
    from (
        select customer_id, date_trunc('month', txn_date) as txn_month, sum(txn_status) as txn_amount
        from (
            select *,
            case when txn_type ='deposit' then txn_amount else -1*txn_amount end as txn_status
            from data_bank.customer_transactions
            order by customer_id, txn_date
        ) deposit_txn
        group by 1,2
    ) total_deposit
),
growth_rate as (
    select *, case when previous_month_bal is null then null
    when previous_month_bal =0 then closing_bal*100 else
    round(((closing_bal - (previous_month_bal))/abs(previous_month_bal))*100) end as growth_rate,
    row_number() over(partition by customer_id order by txn_month desc) as bal_index
    from (
        select *, lag(closing_bal) over(partition by customer_id order by txn_month) as previous_month_bal
        from closing_bal
    )previous_bal
),
cust_last_bal as (
    select customer_id, closing_bal, growth_rate,
    case when growth_rate > 5 then 1 else 0 end as growth_rate_check
    from growth_rate
    where bal_index = 1
)
select round((sum(growth_rate_check)/count(*)::numeric) * 100,1) as user_increase_bal_by_5
from cust_last_bal;
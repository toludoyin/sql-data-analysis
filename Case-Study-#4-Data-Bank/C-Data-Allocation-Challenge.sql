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
data_stores as (
    select *, case when previous_month_bal < 0 then 0 else previous_month_bal end as data_store,
    case when previous_month_bal is null then null
    when previous_month_bal =0 then closing_bal*100 else
    round(((closing_bal - (previous_month_bal))/abs(previous_month_bal))*100) end as growth_rate,
    row_number() over(partition by customer_id order by txn_month desc) as bal_index
    from (
        select *, lag(closing_bal) over(partition by customer_id order by txn_month) as previous_month_bal
        from closing_bal
        )previous_bal
)
select txn_month, sum(data_store) as data_storage
from data_stores
group by 1
order by 1;

-- Option 2
with txn_deposit as (
    select *, case when txn_type = 'deposit'
    then txn_amount else -1 * txn_amount end as txn_group
    from data_bank.customer_transactions
),
date_series as (
    select customer_id, generate_series(first_date, last_date, '1 day') as date_series
    from (
        select customer_id, max(txn_date) as last_date,
        min(txn_date) as first_date
        from txn_deposit
        group by 1
    ) min_max_series
),
customer_balance as (
    select *, sum(txn_group) over (partition by customer_id order by date_series) as txn_sum
    from (
        select ds.customer_id, date_series, txn_group,
        count(txn_group) over (partition by ds.customer_id order by date_series) as txn_count
        from date_series ds
        left join txn_deposit td on ds.customer_id = td.customer_id
        and ds.date_series = td.txn_date
        order by ds.customer_id, date_series
    ) as cust_bal_count
),
customer_data as (
    select customer_id, date_series, case when txn_row_no < 30 then NULL
    when avg_last_30_days < 0 then 0
    else avg_last_30_days end as data_store
    from (
        select *,
        avg(txn_sum) over(partition by customer_id order by date_series rows between 30 preceding and current row) as avg_last_30_days,
        row_number() over(partition by customer_id order by date_series) as txn_row_no
        from customer_balance
        order by 1
    ) as last_30_days
)
select
month, round(sum(data_allocation),1) as total_allocation
from (
    select customer_id,
    date_trunc('month', date_series) as month,
    max(data_store) as data_allocation
    from customer_data
    group by customer_id,month
) as allocated_data
group by 1
order by 1
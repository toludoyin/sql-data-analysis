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
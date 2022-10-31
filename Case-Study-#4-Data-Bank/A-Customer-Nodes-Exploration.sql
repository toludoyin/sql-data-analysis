-- 1. How many unique nodes are there on the Data Bank system?
select distinct node_id as num_of_nodes
from data_bank.customer_nodes
order by 1;

-- 2. What is the number of nodes per region?
select
region_id, region_name, count(distinct node_id) as num_of_nodes
from data_bank.customer_nodes
join data_bank.regions using(region_id)
group by 1,2
order by 1;

-- 3. How many customers are allocated to each region?
select
region_id, region_name, count(distinct customer_id) as num_of_cust
from data_bank.customer_nodes
join data_bank.regions using(region_id)
group by 1,2
order by 1;

-- 4. How many days on average are customers reallocated to a different node?
select round(avg(end_date - start_date),1) as avg_date
from (
    select
    customer_id, start_date,
    case when end_date > current_date then '2020-12-31'::date else end_date end as end_date
    from data_bank.customer_nodes
  )avg_date;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
with nodes as (
    select *, end_date - start_date as node_days
    from (
        select
        region_id, start_date,
        case when end_date > current_date then '2020-12-31'::date else end_date end as end_date
        from data_bank.customer_nodes
    )tmp
 )
select
region_id, percentile_cont(0.5) within group (order by node_days) as median,
percentile_cont(0.8) within group (order by node_days) as q80,
round(percentile_cont(0.95) within group (order by node_days)::numeric,1) as q95
from nodes
group by region_id;
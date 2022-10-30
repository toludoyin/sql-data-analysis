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

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?



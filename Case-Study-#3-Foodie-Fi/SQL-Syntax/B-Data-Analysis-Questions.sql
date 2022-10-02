-- 1. How many customers has Foodie-Fi ever had?
select
count(distinct customer_id) as num_of_customers
from foodie_fi.subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select
date_trunc('month', start_date) as month_start,
count(distinct customer_id) as num_of_cust
from foodie_fi.subscriptions
join foodie_fi.plans using(plan_id)
where plan_name = 'trial'
group by 1;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select
plan_name,
count(*) as num_of_event
from foodie_fi.subscriptions
join foodie_fi.plans using(plan_id)
where extract (year from start_date) >= 2020
group by 1
order by 2 desc;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select
churn_cust as churn_count,
total_cust,
round((churn_cust/total_cust::numeric),1)*100 as churn_pertcg
from (
    select
    count(distinct customer_id) as total_cust,
    count(distinct customer_id) filter (where plan_name = 'churn')as churn_cust
    from foodie_fi.subscriptions
    join foodie_fi.plans using(plan_id)
    ) as churn;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
select *,
round((churn_after_trial/total_cust::numeric)* 100) as churn_after_trial_pretcg
from (
  select
  count(distinct customer_id) as total_cust,
  count(distinct customer_id) filter (where rn = 2 and plan_name ='churn') as churn_after_trial
  from (
    select *,
    row_number() over(partition by customer_id order by start_date) as rn
    from foodie_fi.subscriptions
    join foodie_fi.plans using(plan_id)
    order by 2
  ) as churn_rn
) as end_;

-- 6. What is the number and percentage of customer plans after their initial free trial?
select *,
round(churn_after_trial::numeric/sum(churn_after_trial) over() * 100,1) as churn_after_trial_pretcg
from (
    select
    plan_name,
    count(distinct customer_id) filter (where rn = 2) as churn_after_trial
    from (
        select *,
        row_number() over(partition by customer_id order by start_date) as rn
        from foodie_fi.subscriptions
        join foodie_fi.plans using(plan_id)
        order by 2
    ) as churn_rn
    group by 1
) as end_
where plan_name <> 'trial'
group by 1,2
order by 2 desc;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cust as (
select *, row_number() over(partition by customer_id order by start_date) as rn
from foodie_fi.subscriptions
join foodie_fi.plans using(plan_id)
where start_date::date <= '2020-12-31'::date
order by 2
),
max_row as (
select
customer_id, max(rn) as max_row_num
from cust
group by 1
)
select *, round(no_of_cust::numeric/sum(no_of_cust) over()*100,1) as pertcg
from (
    select
    plan_id,
    count(*) as no_of_cust
    from cust cc
    join max_row mr on cc.customer_id = mr.customer_id
    and cc.rn = mr.max_row_num
    group by 1
) as end_
group by 1,2;

-- 8. How many customers have upgraded to an annual plan in 2020?
select
plan_name,
count(*) as num_of_event
from foodie_fi.subscriptions
join foodie_fi.plans using(plan_id)
where extract (year from start_date) = 2020 and plan_name = 'pro annual'
group by 1
order by 2 desc;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
select round(avg(annual.start_date - trial.start_date)) as avg_date
from foodie_fi.subscriptions trial
join foodie_fi.subscriptions annual using(customer_id)
where trial.plan_id = 0 and annual.plan_id = 3;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with date_diff as (
select customer_id,
trial.start_date, annual.start_date,
annual.start_date - trial.start_date as date_diff
from foodie_fi.subscriptions trial
join foodie_fi.subscriptions annual using(customer_id)
where trial.plan_id = 0 and annual.plan_id = 3
order by 4 desc
)
select avg_period_breakdown, round(avg(date_diff),1)
from (
    select *,
    case when date_diff between 0 and 30 then '0-30'
    when date_diff between 31 and 60 then '31-60'
    when date_diff between 61 and 90 then '61-90'
    when date_diff between 91 and 120 then '91-120'
    when date_diff between 121 and 150 then '121-150'
    when date_diff between 151 and 180 then '151-180'
    when date_diff >= 181 then '>= 181'
    end as avg_period_breakdown
    from date_diff
) as breakdown
group by 1
order by 2;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select customer_id, pro.plan_id, pro.start_date as pro_date,
basic.plan_id, basic.start_date as basic_date
from foodie_fi.subscriptions pro
join foodie_fi.subscriptions basic using(customer_id)
where pro.plan_id = 2 AND basic.plan_id = 1
and pro.start_date < basic.start_date
and extract (year from basic.start_date) = 2020
order by 4 desc;
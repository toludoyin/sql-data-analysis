/**
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

* monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
* upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
* upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments
**/

with sub as (
select * from foodie_fi.plans
join foodie_fi.subscriptions using(plan_id)
where plan_name <> 'trial'
),
customer_journey as (
select
customer_id, array_agg(plan_id) as plan_journey,
array_agg(start_date) as sub_date
from sub
group by 1
),
payment as (
-- 1st and 2nd subscripion plan
select
customer_id, plan_journey, sub_date, min(series) as series
from (
    select *,
    generate_series(sub_date[1], coalesce(sub_date[2]-interval '1 day', '2020-12-31'), '1 month') as series
    from  customer_journey
    ) as tmp
where plan_journey[1]= 3
group by 1,2,3
union all
select *,
generate_series(sub_date[1], coalesce(sub_date[2]-interval '1 day', '2020-12-31'), '1 month') as series
from  customer_journey
where plan_journey[1] <> 3

union all

 -- 2nd and 3rd subscription plan
select *,
generate_series(sub_date[2], coalesce(sub_date[3]-interval '1 day', '2020-12-31'), '1 month') as series
from  customer_journey
where plan_journey in (array[1,2,3], array[1,3,4], array[2,3], array[1,3])
union all
select *,
generate_series(sub_date[2], coalesce(sub_date[3]-interval '1 day', case when plan_journey[2] <>4 then '2020-12-31'::date end), '1 month') as series
from  customer_journey
where plan_journey not in (array[1,2,3], array[1,3,4], array[2,3], array[1,3])
order by 1
),
update_payment as (
select *,
case when plan_journey in (array[1,2], array[1,3])
and array[prev_plan, plan_id] in (array[1,2], array[1,3])
and date_trunc('month', payment_date) = date_trunc('month', prev_payment_date)
then amount-lag_amount else amount end as update_amount
from (
    select *,
    lag(amount) over (partition by customer_id order by payment_date) as lag_amount,
    lag(payment_date) over (partition by customer_id order by payment_date) as prev_payment_date,
    lag(plan_id) over (partition by customer_id order by payment_date) as prev_plan
    from (
        select customer_id,
        max(plan_id) over (partition by customer_id order by series) as plan_id,
        max(pp.plan_name) over (partition by customer_id order by series) as plan_name,
        series as payment_date,
        max(price) over (partition by customer_id order by series) as amount,
        row_number() over (partition by customer_id order by series) as payment_order, plan_journey, sub_date
        from (
            select
            p.customer_id, s.plan_id, p.plan_journey, p.series, p.sub_date
            from payment p
            left join sub s using(customer_id)
            where plan_journey[1] <> 4
            and p.series = s.start_date
            and extract(year from series)=2020
            order by 1,4
            ) as tmp
        left join foodie_fi.plans pp using(plan_id)
        ) as tmp
    ) as tmp
)
select
customer_id, plan_id, plan_name, payment_date, amount, payment_order
from update_payment;
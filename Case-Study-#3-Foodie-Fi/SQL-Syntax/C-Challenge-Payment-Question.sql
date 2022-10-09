/**
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

* monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
* upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
* upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments
**/

/**
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

    payment as (-- 1st and 2nd subscripion
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

 -- 2nd and 3rd subscription
 select *,
    generate_series(sub_date[2], coalesce(sub_date[3]-interval '1 day', '2020-12-31'), '1 month') as series
                    from  customer_journey
    where plan_journey in (array[1,2,3], array[1,3,4], array[2,3], array[1,3])

 union all

 select *,
    generate_series(sub_date[2], coalesce(sub_date[3]-interval '1 day', case when plan_journey[2] <>4 then '2020-12-31'::date end), '1 month') as series --remove users who churn after trial
                    from  customer_journey
    where plan_journey not in (array[1,2,3], array[1,3,4], array[2,3], array[1,3])
    order by 1
      ) select * from payment
      order by 1
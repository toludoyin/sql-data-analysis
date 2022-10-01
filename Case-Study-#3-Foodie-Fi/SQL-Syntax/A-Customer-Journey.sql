/**
-------------------------------
 CASE STUDY A. Customer Journey
-------------------------------
Tools used: PostgreSQL

QUESTION
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
**/

/**
-------
ANSWERS
-------
From the 1000 users, 8 sample customers (with customer_id 1, 2, 11, 13, 15, 16,18 and 19) were provided in the sample from the subscription table.
customer_id 1: Downgraded to a basic plan after the 7-days trial.

customer_id 2: Upgraded to pro annual plan after the trial.

customer_id 11: Churned after the trial period.

customer_id 13: Downgrade to basic plan after trial period, upgraded to pro-monthly 4-month after.

customer_id 15: After the trial, churned after a month of using pro monthly plan.

customer_id 16: After the trial, downgraded to basic, and after 4-month upgraded to pro monthly.

customer_id 18: After the trail, remained in pro monthly plan after 7-days trial.

customer_id 19: After trail, remained in pro monthly plan. and after 2-month pgraded to pro annual.
**/

select
*
from foodie_fi.plans
join foodie_fi.subscriptions using(plan_id)
where customer_id = 1  --input customer_id here
order by start_date




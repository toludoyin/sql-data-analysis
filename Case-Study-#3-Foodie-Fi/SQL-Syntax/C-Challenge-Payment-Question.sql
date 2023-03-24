/**
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

* monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
* upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
* upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments
**/

WITH sub AS (
SELECT * FROM foodie_fi.plans
JOIN foodie_fi.subscriptions USING(plan_id)
WHERE plan_name <> 'trial'
),
customer_journey AS (
SELECT
    customer_id, ARRAY_AGG(plan_id) AS plan_journey,
    ARRAY_AGG(start_date) AS sub_date
FROM sub
GROUP BY 1
),
payment AS (
-- 1st and 2nd subscripion plan
SELECT
    customer_id, plan_journey, sub_date, min(series) AS series
FROM (
    SELECT *,
    GENERATE_SERIES(sub_date[1], COALESCE(sub_date[2]-interval '1 day', '2020-12-31'), '1 month') AS series
    FROM customer_journey
) AS tmp
WHERE plan_journey[1]= 3
GROUP BY 1,2,3

UNION ALL

SELECT *,
    GENERATE_SERIES(sub_date[1], COALESCE(sub_date[2]-interval '1 day', '2020-12-31'), '1 month') AS series
FROM customer_journey
WHERE plan_journey[1] <> 3

UNION ALL

 -- 2nd and 3rd subscription plan
SELECT *,
    GENERATE_SERIES(sub_date[2], COALESCE(sub_date[3] - interval '1 day', '2020-12-31'), '1 month') AS series
FROM  customer_journey
WHERE plan_journey IN (ARRAY[1,2,3], ARRAY[1,3,4], ARRAY[2,3], ARRAY[1,3])

UNION ALL

SELECT *,
    GENERATE_SERIES(sub_date[2], COALESCE(sub_date[3]-interval '1 day', CASE WHEN plan_journey[2] <>4 THEN '2020-12-31'::DATE END), '1 month') AS series
FROM  customer_journey
WHERE plan_journey NOT IN (ARRAY[1,2,3], ARRAY[1,3,4], ARRAY[2,3], ARRAY[1,3])
ORDER BY 1
),
update_payment AS (
SELECT *,
    CASE WHEN plan_journey IN (ARRAY[1,2],ARRAY[1,3])
    AND ARRAY[prev_plan, plan_id] IN (ARRAY[1,2], ARRAY[1,3])
    AND DATE_TRUNC('MONTH', payment_date) = DATE_TRUNC('MONTH', prev_payment_date)
    THEN amount - lag_amount ELSE amount END AS update_amount
FROM (
    SELECT *,
        LAG(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) AS lag_amount,
        LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_payment_date,
        LAG(plan_id) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_plan
    FROM (
        SELECT customer_id,
        MAX(plan_id) OVER (PARTITION BY customer_id ORDER BY series) AS plan_id,
        MAX(pp.plan_name) OVER (PARTITION BY customer_id ORDER BY series) AS plan_name,
        series as payment_date,
        MAX(price) OVER (PARTITION BY customer_id ORDER BY series) AS amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY series) AS payment_order, plan_journey, sub_date
        FROM (
            SELECT
                p.customer_id, s.plan_id, p.plan_journey, p.series, p.sub_date
            FROM payment p
            LEFT JOIN sub s USING(customer_id)
            WHERE plan_journey[1] <> 4
            AND p.series = s.start_date
            AND EXTRACT(year FROM series)=2020
            ORDER BY 1,4
            ) AS tmp
        LEFT JOIN foodie_fi.plans pp USING (plan_id)
        ) AS tmp
    ) AS tmp
)
SELECT
    customer_id, plan_id, plan_name, payment_date, amount, payment_order
FROM update_payment;
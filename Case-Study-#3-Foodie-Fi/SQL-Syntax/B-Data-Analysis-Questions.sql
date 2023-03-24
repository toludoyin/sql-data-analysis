-- 1. How many customers has Foodie-Fi ever had?
SELECT
COUNT(DISTINCT customer_id) AS num_of_customers
FROM foodie_fi.subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT
    DATE_TRUNC('MONTH', start_date) AS month_start,
    COUNT(DISTINCT customer_id) AS num_of_cust
FROM foodie_fi.subscriptions
JOIN foodie_fi.plans USING(plan_id)
WHERE plan_name = 'trial'
GROUP BY 1;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT
    plan_name,
    COUNT(*) AS num_of_event
FROM foodie_fi.subscriptions
JOIN foodie_fi.plans USING(plan_id)
WHERE EXTRACT(year FROM start_date) >= 2020
GROUP BY 1
ORDER BY 2 DESC;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
    churn_cust AS churn_count,
    total_cust,
    ROUND((churn_cust/total_cust::NUMERIC),1)*100 AS churn_pertcg
FROM (
    SELECT
        COUNT(DISTINCT customer_id) AS total_cust,
        COUNT(DISTINCT customer_id) FILTER (WHERE plan_name = 'churn') AS churn_cust
    FROM foodie_fi.subscriptions
    JOIN foodie_fi.plans USING(plan_id)
) AS churn;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT *,
    ROUND((churn_after_trial/total_cust::NUMERIC)* 100) AS churn_after_trial_pretcg
FROM (
    SELECT
        COUNT(DISTINCT customer_id) AS total_cust,
        COUNT(DISTINCT customer_id) FILTER (WHERE  rn = 2 AND plan_name ='churn') AS churn_after_trial
    FROM (
        SELECT *,
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS rn
        FROM foodie_fi.subscriptions
        JOIN foodie_fi.plans USING(plan_id)
        ORDER BY 2
    ) AS churn_rn
) AS end_;

-- 6. What is the number and percentage of customer plans after their initial free trial?
SELECT *,
    ROUND(churn_after_trial::NUMERIC/SUM(churn_after_trial) OVER() * 100,1) AS churn_after_trial_pretcg
FROM (
    SELECT
        plan_name,
        COUNT(DISTINCT customer_id) FILTER (WHERE rn = 2) AS churn_after_trial
    FROM (
        SELECT *,
            ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS rn
        FROM foodie_fi.subscriptions
        JOIN foodie_fi.plans USING(plan_id)
    ) AS churn_rn
    GROUP BY 1
) AS end_
WHERE plan_name <> 'trial'
GROUP BY 1,2
ORDER BY 2 desc;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH cust AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) AS rn
    FROM foodie_fi.subscriptions
    JOIN foodie_fi.plans USING(plan_id)
    WHERE start_date::DATE <= '2020-12-31'::DATE
    ORDER BY 2
),
max_row as (
    SELECT
        customer_id, MAX(rn) AS max_row_num
    FROM cust
    GROUP BY 1
)
SELECT *, ROUND(no_of_cust::NUMERIC/SUM(no_of_cust) OVER()*100,1) AS pertcg
FROM (
    SELECT
        plan_id,
        COUNT(*) AS no_of_cust
    FROM cust cc
    JOIN max_row mr ON cc.customer_id = mr.customer_id
    AND cc.rn = mr.max_row_num
    GROUP BY 1
) AS end_
GROUP BY 1,2;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT
    plan_name,
    COUNT(*) AS num_of_event
FROM foodie_fi.subscriptions
JOIN foodie_fi.plans USING(plan_id)
WHERE EXTRACT(YEAR FROM start_date) = 2020
AND plan_name = 'pro annual'
GROUP BY 1
ORDER BY 2 DESC;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT
    ROUND(AVG(annual.start_date - trial.start_date)) AS avg_date
FROM foodie_fi.subscriptions trial
JOIN foodie_fi.subscriptions annual USING(customer_id)
JOIN trial.plan_id = 0 AND annual.plan_id = 3;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH date_diff AS (
SELECT customer_id,
    trial.start_date, annual.start_date,
    annual.start_date - trial.start_date AS date_diff
FROM foodie_fi.subscriptions trial
JOIN foodie_fi.subscriptions annual USING(customer_id)
JOIN trial.plan_id = 0
AND annual.plan_id = 3
ORDER BY 4 DESC
)
SELECT
    avg_period_breakdown, ROUND(AVG(date_diff),1)
FROM (
    SELECT *,
        CASE WHEN date_diff BETWEEN 0 AND 30 THEN '0-30'
        WHEN date_diff BETWEEN 31 AND 60 THEN '31-60'
        WHEN date_diff BETWEEN 61 AND 90 THEN '61-90'
        WHEN date_diff BETWEEN 91 AND 120 THEN '91-120'
        WHEN date_diff BETWEEN 121 AND 150 THEN '121-150'
        WHEN date_diff BETWEEN 151 AND 180 THEN '151-180'
        WHEN date_diff >= 181 THEN '>= 181'
        END AS avg_period_breakdown
    FROM date_diff
) AS breakdown
GROUP BY 1
ORDER BY 2;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT
    customer_id, pro.plan_id, pro.start_date AS pro_date,
    basic.plan_id, basic.start_date AS basic_date
FROM foodie_fi.subscriptions pro
JOIN foodie_fi.subscriptions basic using(customer_id)
WHERE pro.plan_id = 2 AND basic.plan_id = 1
AND pro.start_date < basic.start_date
AND EXTRACT(YEAR FROM basic.start_date) = 2020
ORDER BY 4 DESC;
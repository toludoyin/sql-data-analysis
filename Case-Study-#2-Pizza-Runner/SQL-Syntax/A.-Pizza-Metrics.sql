------------------------------
-- CASE STUDY A. PIZZA METRICS
------------------------------
--Tools used: PostgreSQL

-- 1. How many pizzas were ordered?
SELECT
    COUNT(pizza_id) AS total_pizzas_ordered
FROM pizza_runner.customer_orders;

-- 2. How many unique customer orders were made?
SELECT
    COUNT(DISTINCT order_id) AS unique_customers
FROM pizza_runner.customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id,
   COUNT(order_id) AS num_of_orders_delivered
FROM (
    SELECT *,
        CASE WHEN Cancellation = 'null'
        OR Cancellation IS NULL
        OR Cancellation = '' THEN 0 ELSE 1 END AS cancellation2
    FROM pizza_runner.runner_orders
) AS successful_orders
WHERE cancellation2 = 0
GROUP BY 1
ORDER BY 1;

-- 4. How many of each type of pizza was delivered?
WITH pizza_types AS (
    SELECT *,
        CASE WHEN Cancellation = 'null'
        OR Cancellation IS NULL
        OR Cancellation = '' THEN 0 ELSE 1 END AS cancellation2
    FROM pizza_runner.runner_orders ro
    JOIN pizza_runner.customer_orders co USING(order_id)
    LEFT JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
)
SELECT
    pizza_name,
    COUNT(order_id) AS num_of_orders
FROM pizza_types
WHERE cancellation2 = 0
GROUP BY 1
ORDER BY 1;

-- 5.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    customer_id,
    COALESCE(COUNT(CASE WHEN pizza_name='Meatlovers' THEN order_id END),0) AS Meatlovers,
    coalesce(count(CASE WHEN pizza_name='Vegetarian' THEN order_id END),0) AS Vegetarian
FROM pizza_runner.runner_orders ro
JOIN pizza_runner.customer_orders co USING(order_id)
LEFT JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY 1
ORDER BY 1;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT
    order_id,
    COUNT(pizza_id) AS num_of_pizzas_delivered
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 2 DESC;

-- 7 and 8
WITH cleaned_data AS (
    SELECT *,
        CASE WHEN exclusions IN ('null', '') OR exclusions IS NULL THEN '0'
        ELSE exclusions END AS exclusion,
        CASE WHEN extras IN ('null', '') OR extras IS NULL THEN '0'
        ELSE extras END AS extra
    FROM pizza_runner.customer_orders
    WHERE order_id IN (
        SELECT DISTINCT order_id FROM (
            SELECT *,
                CASE WHEN Cancellation IS NULL OR Cancellation in('null', '') THEN 0 ELSE 1 END AS cancellation2
            FROM pizza_runner.runner_orders
        ) AS successful_pizza
        WHERE cancellation2 = 0
    )
),
create_change_col AS (
   SELECT *,
        CASE WHEN exclusion = '0' AND extra = '0' THEN 0 ELSE 1 END AS change
    FROM cleaned_data
),
made_changes AS (
    SELECT
        customer_id,
        COUNT(order_id) FILTER (WHERE change::INT = 0) AS pizza_no_changes,
        COUNT(order_id) FILTER (WHERE change::INT > 0) AS pizza_changes
    FROM create_change_col
    GROUP BY 1
    ORDER BY 1
),   -- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
made_both_change AS (
    SELECT
        customer_id,
        COUNT(order_id) FILTER (WHERE exclu_change::INT > 0 AND extra_change::INT > 0) AS exclusion_extra
    FROM (
        SELECT *,
            CASE WHEN exclusion = '0' THEN 0 ELSE 1 END AS exclu_change,
            CASE WHEN extra = '0' THEN 0 ELSE 1 END AS extra_change
        FROM create_change_col
        ) AS made_both_changes
    GROUP BY 1
    ORDER BY 1
)       --8. How many pizzas were delivered that had both exclusions and extras?
SELECT *
-- FROM made_changes       -- 7.
FROM made_both_change;      -- 8.

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
    EXTRACT(hour FROM order_time) AS hour_of_day,
    COUNT(order_id) AS num_of_order
FROM pizza_runner.customer_orders
GROUP BY 1;

-- 10. What was the volume of orders for each day of the week?
SELECT
    TO_CHAR(order_time, 'Day') AS day_of_week,
    EXTRACT(dow FROM order_time) AS week_day,
    COUNT(order_id) AS num_of_orders
FROM pizza_runner.customer_orders
GROUP BY 1,2
ORDER BY 3 DESC;
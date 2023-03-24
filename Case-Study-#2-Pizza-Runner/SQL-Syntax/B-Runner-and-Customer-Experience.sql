-----------------------------------
--B. Runner and Customer Experience
-----------------------------------

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
    DATE_TRUNC('week', registration_date) AS registratin_week,
    CONCAT('Week ', TO_CHAR(registration_date, 'ww')) AS week_no,
    COUNT(DISTINCT runner_id) AS num_of_runners
FROM pizza_runner.runners
GROUP BY 1,2
ORDER BY 1;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
    runner_id,
    ROUND(AVG(arrival_time)) AS avg_minute
FROM (
    SELECT
        runner_id,
        EXTRACT(minute FROM (pickup_time - order_time)) AS arrival_time
    FROM (
        SELECT
            runner_id,
            order_time,
            CASE WHEN pickup_time IN ('null', '') THEN NULL ELSE to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS') END AS pickup_time,
            CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation
        FROM pizza_runner.runner_orders
        LEFT JOIN (
            SELECT
                DISTINCT order_id, order_time -- remove duplicate
            FROM pizza_runner.customer_orders
        ) AS unique_orders
        USING(order_id)
    ) AS time_period
    WHERE cancellation !=1
) AS avg_minutes
GROUP BY 1
ORDER BY 1;

/**3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
ANSWER: YES, there is a relationship between the number of pizza and the time it takes to prepare it. The more the number of pizza ordered , the longer the time
**/
SELECT
    pizza_ordered,
    ROUND(AVG(prepare_time_minute)) AS avg_minute
FROM (
    SELECT
        pizza_ordered,
        EXTRACT(minute FROM (pickup_time - order_time)) AS prepare_time_minute
    FROM (
        SELECT
            order_id,
            order_time, pizza_ordered,
            CASE WHEN pickup_time IN ('null', '') THEN NULL ELSE to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS') END AS pickup_time,
            CASE WHENn cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation
        FROM pizza_runner.runner_orders
        LEFT JOIN (
            SELECT
                order_id, order_time,
                COUNT(order_id) AS pizza_ordered
            FROM pizza_runner.customer_orders
            GROUP BY 1,2
        ) AS unique_orders USING(order_id)
    ) AS time_period
    WHERE cancellation !=1
) AS avg_minutes
GROUP BY 1
ORDER BY 1;

-- 4. What was the average distance travelled for each customer?
WITH distances AS (
    SELECT
        DISTINCT order_id,
        customer_id,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE END AS cancellation,
        CASE WHEN distance IN ('null','') THEN NUll ELSE split_part(distance, 'km', 1) END AS distance
    FROM pizza_runner.runner_orders
    LEFT JOIN pizza_runner.customer_orders USING(order_id)
)
SELECT
    customer_id,
    AVG(distance::FLOAT) AS avg_distance
FROM distances
WHERE cancellation !=1
GROUP BY 1
ORDER BY 1;


-- 5. What was the difference between the longest and shortest delivery times for all orders?
WITH duration AS (
    SELECT
        DISTINCT order_id,
        customer_id,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation,
        CASE WHEN duration IN ('null','') THEN NUll ELSE SPLIT_PART(duration, 'min', 1)::INT END AS duration
    FROM pizza_runner.runner_orders
    LEFT JOIN pizza_runner.customer_orders USING(order_id)
)
SELECT
    MIN(duration) AS shortest_delivery,
    MAX(duration) AS longest_delivey,
    (MAX(duration) - MIN(duration)) AS difference_in_delivery
FROM duration
WHERE cancellation != 1
ORDER BY 1;


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- ANSWER: For each runner, their average speed rate(km per hour) increase after their first delivery.
WITH runners AS (
    SELECT
        DISTINCT runner_id, order_id,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation,
        CASE WHEN distance IN ('null','') THEN NUll ELSE split_part(distance, 'km', 1)::FLOAT END AS distance,
        CASE WHEN duration IN ('null','') THEN NUll ELSE split_part(duration, 'min', 1)::INT END AS duration_minute
    FROM pizza_runner.runner_orders
)
SELECT
    runner_id, order_id,
    avg(distance/(duration_minute/60.0)) as speed_km_per_hr
FROM runners
WHERE cancellation != 1
GROUP BY 1,2
ORDER BY 1;

-- 7. What is the successful delivery percentage for each runner?
WITH runners AS (
    SELECT
        DISTINCT runner_id, order_id,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation,
        CASE WHEN distance IN ('null','') THEN NUll ELSE split_part(distance, 'km', 1)::FLOAT END AS distance,
        CASE WHEN duration in ('null','') THEN NUll ELSE split_part(duration, 'min', 1)::INT END AS duration_minute
    FROM pizza_runner.runner_orders
)
SELECT
    runner_id,
    COUNT(CASE WHEN cancellation = 0 THEN cancellation END) AS successful_delivery,
    COUNT(*) AS total_delivery,
    (COUNT(CASE WHEN cancellation = 0 THEN cancellation END))/ COUNT(*)::FLOAT AS successful_delivery_percent
FROM runners
GROUP BY 1
ORDER BY 1;
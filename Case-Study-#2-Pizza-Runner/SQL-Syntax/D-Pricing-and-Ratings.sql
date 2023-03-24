------------------------
-- D. Pricing and Rating
------------------------

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were
-- no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH delivered_order AS (
    SELECT
        order_id, pizza_id,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation
    FROM pizza_runner.runner_orders
    JOIN pizza_runner.customer_orders USING(order_id)
),
pizza_price AS (
    SELECT
        order_id, pizza_id, pizza_name,
        (CASE WHEN pizza_name = 'Meatlovers' THEN 12::INT ELSE 10::INT END) AS pizza_cost
    FROM delivered_order
    JOIN pizza_runner.pizza_names USING(pizza_id)
    WHERE cancellation =0
)
SELECT
    pizza_name,
    SUM(pizza_cost) AS total_pizza_cost
FROM pizza_price
GROUP BY 1;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- * Add cheese is $1 extra
WITH delivered_order AS (
    SELECT
        order_id, pizza_id,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation,
        CASE WHEN extras IN ('null', '') THEN NULL ELSE extras END AS extras
    FROM pizza_runner.runner_orders
    JOIN pizza_runner.customer_orders USING(order_id)
),
pizza_price AS (
    SELECT
        order_id, pizza_id, extras, pizza_name,
        (CASE WHEN pizza_name = 'Meatlovers' THEN 12::INT ELSE 10::INT END) AS pizza_amount
    FROM delivered_order
    JOIN pizza_runner.pizza_names USING(pizza_id)
    WHERE cancellation = 0
)
SELECT
    pizza_name,
    SUM(pizza_amount) + SUM(extra_charges) AS total_amount
FROM (
    SELECT
        *, (CASE WHEN num_of_extras IS NOT NULL THEN num_of_extras *1::INT ELSE 0::INT END) AS extra_charges
    FROM (
       SELECT
            *, extras,
            ARRAY_LENGTH(STRING_TO_ARRAY(extras, ', '), 1) AS num_of_extras
        FROM pizza_price
    ) AS charges_on_extra
) AS price_and_charges
GROUP BY 1;

/*3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
NOTE: full schema available in new_schema.sql file
*/
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (
"order_id" INTEGER,
"rating" INTEGER
);
INSERT INTO ratings
("order_id", "rating")
VALUES
('1', '1'),
('2', '3'),
('3', '4'),
('4', '2'),
('5', '3'),
('6', '0'),
('7', '1'),
('8', '2'),
('9', '0'),
('10', '5');
-- query
SELECT * FROM pizza_runner.ratings

/*4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
* customer_id
* order_id
* runner_id
* rating
* order_time
* pickup_time
* Time between order and pickup
* Delivery duration
* Average speed
* Total number of pizzas
*/
WITH delivered_order AS (
    SELECT
        customer_id, order_id, runner_id, order_time,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation,
        CASE WHEN distance IN ('null','') THEN NUll ELSE SPLIT_PART(distance, 'km', 1)::FLOAT END AS distance,
        CASE WHEN duration IN ('null','') THEN NUll ELSE SPLIT_PART(duration, 'min', 1)::INT END AS duration_minute,
        CASE WHEN pickup_time IN ('null', '') THEN NULL ELSE to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS') END AS pickup_time
    FROM pizza_runner.runner_orders
    JOIN pizza_runner.customer_orders USING(order_id)
)
SELECT
    customer_id, order_id, runner_id,
    order_time, pickup_time, rating,
    EXTRACT(minute FROM (pickup_time - order_time)) AS time_bet_order_and_pickup,
    duration_minute,
    AVG(distance::FLOAT/(duration_minute::INT/60.0)) AS average_speed, total_num_of_pizzas
FROM (
    SELECT
        customer_id, order_id, runner_id,
        pickup_time, duration_minute, distance,
        MIN(order_time) AS order_time,
        COUNT(*) AS total_num_of_pizzas
    FROM delivered_order
    WHERE cancellation = 0
    GROUP BY 1,2,3,4,5,6
) AS new_table
JOIN pizza_runner.ratings r USING(order_id)
GROUP BY 1,2,3,4,5,6,7,8,10
ORDER BY 1;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no
-- cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH  delivered_order AS (
    SELECT
        order_id, pizza_id, runner_id,
        CASE WHEN cancellation IN ('null','') OR cancellation IS NULL THEN 0 ELSE 1 END AS cancellation,
        CASE WHEN distance IN ('null','') THEN NULL ELSE SPLIT_PART(distance, 'km', 1)::FLOAT END AS distance
    FROM pizza_runner.runner_orders
    JOIN pizza_runner.customer_orders USING(order_id)
),
pizza_price AS (
    SELECT
        order_id, pizza_id, pizza_name,
        runner_id, distance,
        (CASE WHEN pizza_name = 'Meatlovers' THEN 12::INT ELSE 10::INT END) AS pizza_cost
    FROM delivered_order
    JOIN pizza_runner.pizza_names USING(pizza_id)
    WHERE cancellation = 0
)
SELECT
    pizza_name,
    SUM(pizza_cost) AS total_pizza_revenue,
    SUM(distance::FLOAT * 0.30) AS delivery_cost,
    (SUM(pizza_cost) - SUM(distance::FLOAT *0.30)) AS gross_profit
FROM pizza_price
GROUP BY 1;
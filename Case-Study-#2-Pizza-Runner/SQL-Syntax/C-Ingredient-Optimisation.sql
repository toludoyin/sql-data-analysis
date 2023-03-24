----------------------------
--C. INGREDIENT OPTIMIZATION
----------------------------

-- 1. What are the standard ingredients for each pizza?
WITH topping_nest AS (
    SELECT
        pizza_id,
        UNNEST(STRING_TO_ARRAY(toppings, ','))::INT AS topping_id
    FROM pizza_runner.pizza_recipes
),
ingredient AS (
    SELECT * FROM topping_nest
    JOIN pizza_runner.pizza_toppings USING(topping_id)
    LEFT JOIN pizza_runner.pizza_names USING(pizza_id)
)
SELECT
    pizza_name,
    STRING_AGG(topping_name, ',') AS standard_ingredient
FROM ingredient
GROUP BY  1;

-- 2. What was the most commonly added extra?
WITH pizza_topping AS (
    SELECT
        pizza_id,
        UNNEST(STRING_TO_ARRAY(extras, ','))::INT AS topping_id
    FROM (
        SELECT
            pizza_id,
            CASE WHEN extras in ('null', '') THEN NULL ELSE extras END AS extras
        FROM pizza_runner.customer_orders
    ) AS pizza_extra
)
SELECT
    topping_name,
    COUNT(pizza_id) AS num_of_toppings
FROM pizza_topping
JOIN pizza_runner.pizza_toppings USING(topping_id)
GROUP BY  1
ORDER BY 2 DESC
LIMIT 1;

-- 3. What was the most common exclusion?
WITH pizza_topping AS (
    SELECT
        pizza_id,
        UNNEST(STRING_TO_ARRAY(exclusions, ','))::INT AS topping_id
    FROM (
        SELECT
            pizza_id,
            CASE WHEN exclusions IN ('null', '') THEN NULL ELSE exclusions END AS exclusions
        FROM pizza_runner.customer_orders
    ) AS pizza_exclusions
)
SELECT
    topping_name,
    COUNT(pizza_id) AS num_of_toppings
FROM pizza_topping
JOIN pizza_runner.pizza_toppings USING(topping_id)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

/**4. Generate an order item for each record in the customers_orders table in the format of one of the following:
* Meat Lovers
* Meat Lovers - Exclude Beef
* Meat Lovers - Extra Bacon
* Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
**/
WITH row_indexx AS (
    SELECT *,
        ROW_NUMBER() OVER() AS row_index
    FROM pizza_runner.customer_orders
),
extras AS (
    SELECT order_id, pizza_id, row_index, topping_name
    FROM (
        SELECT * FROM (
            SELECT
                order_id, pizza_id, row_index,
                UNNEST(STRING_TO_ARRAY(extras, ',')) AS extras
            FROM row_indexx
        ) AS extras_temp
        WHERE extras NOT IN ('null', '')
    ) AS extrass
    JOIN pizza_runner.pizza_toppings ON extras::INT = topping_id
),
exclusions AS (
    SELECT order_id, pizza_id, row_index, topping_name
    FROM (
        SELECT * FROM (
            SELECT
                order_id, pizza_id, row_index,
                UNNEST(STRING_TO_ARRAY(exclusions, ',')) AS exclusions
            FROM row_indexx
        ) AS exclusions_temp
        WHERE exclusions NOT IN ('null', '')
    ) AS exclusionss
    JOIN pizza_runner.pizza_toppings ON exclusions::INT = topping_id
),
extra_toppings as (
    SELECT
        row_index,
        STRING_AGG(topping_name, ', ') AS extra
    FROM extras
    GROUP BY 1
),
exclusions_toppings AS (
    SELECT
        row_index,
        STRING_AGG(topping_name, ', ') AS exclusion
    FROM exclusions
    GROUP BY 1
)
SELECT
    CONCAT(pizza_name,
    CASE WHEN e.extra IS NULL THEN '' ELSE '- Exclude ' END, e.extra,
    CASE WHEN t.exclusion IS NULL THEN '' ELSE ' - Exclude ' END,
    t.exclusion) AS pizza_ordered
FROM row_indexx ri
LEFT JOIN extra_toppings e USING(row_index)
LEFT JOIN exclusions_toppings t USING(row_index)
JOIN pizza_runner.pizza_names USING(pizza_id)
WHERE pizza_name = 'Meatlovers';

/**5. Generate an alphabetically ordered comma separated ingredient list for
each pizza order from the customer_orders table and add a 2x in front of any
relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
**/
WITH row_indexx AS (
    SELECT *,
        ROW_NUMBER() OVER() AS row_index
    FROM pizza_runner.customer_orders
),
extras AS (
    SELECT order_id, pizza_id, row_index, topping_name
    FROM (
        SELECT * FROM (
            SELECT
                order_id, pizza_id, row_index,
                UNNEST(STRING_TO_ARRAY(extras, ',')) AS extras
            FROM row_indexx
        ) AS extras_temp
        WHERE extras NOT IN ('null', '')
    ) AS extrass
    JOIN pizza_runner.pizza_toppings ON extras::INT = topping_id
),
exclusions AS (
    SELECT order_id, pizza_id, row_index, topping_name
    FROM (
        SELECT * FROM (
            SELECT
                order_id, pizza_id, row_index,
                UNNEST(STRING_TO_ARRAY(exclusions, ',')) AS exclusions
            FROM row_indexx
        ) AS exclusions_temp
        WHERE exclusions NOT IN ('null', '')
    ) AS exclusionss
    JOIN pizza_runner.pizza_toppings ON exclusions::INT = topping_id
),
exclusions_toppings AS (
    SELECT
        row_index, pizza_id, topping_name,
        CONCAT(row_index,',',topping_name) AS row_index_toppings
    FROM exclusions
),
topping_unnest AS (
    SELECT
        row_index, pizza_id,
        UNNEST(STRING_TO_ARRAY(toppings, ',')) AS toppings
    FROM row_indexx ri
    JOIN pizza_runner.pizza_recipes USING(pizza_id)
    ORDER BY 1
),
order_array AS (
    SELECT
        row_index, pizza_id, toppings, topping_name,
        CONCAT(row_index, ',', topping_name) AS row_index_toppings
    FROM topping_unnest tu
    JOIN pizza_runner.pizza_toppings pt ON tu.toppings::INT = pt.topping_id
    ORDER BY row_index
),
ingredient AS (
    SELECT * FROM (
        SELECT
            row_index, pizza_id,
            SPLIT_PART(row_index_toppings, ',', 2) AS topping_name
        FROM  order_array
        WHERE row_index_toppings NOT IN (
            SELECT row_index_toppings
            FROM exclusions_toppings
        )
        UNION ALL

        SELECT row_index, pizza_id, topping_name
        FROM extras
    ) AS pizza_ingd
    ORDER BY 1,2,3
)
SELECT
    CONCAT(pizza_name, ': ', topping_name) AS pizza_ingredient_list
FROM (
    SELECT
        row_index, pizza_id,
        STRING_AGG(CASE WHEN multiple_ingrd = 1 THEN topping_name ELSE
        CONCAT(multiple_ingrd, 'x', topping_name) END, ', ') AS topping_name
    FROM (
        SELECT
            row_index, pizza_id, topping_name,
            COUNT(*) AS multiple_ingrd
        FROM ingredient
        GROUP BY 1,2,3
    ) AS ingd_count
    GROUP BY 1,2
) AS pizza_ingredient
JOIN pizza_runner. pizza_names USING(pizza_id);

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH delivered_order AS (
    SELECT order_id FROM (
        SELECT
            order_id,
            CASE WHEN cancellation IN ('null','') OR cancellation IS NUll THEN 0 ELSE 1 END AS cancellation
        FROM pizza_runner.runner_orders
        JOIN pizza_runner.customer_orders USING(order_id)
    ) AS orders
    WHERE cancellation =0
),
order_row_index AS (
    SELECT *,
        ROW_NUMBER() OVER() AS row_index
    FROM pizza_runner.customer_orders
    WHERE order_id IN (
        SELECT order_id
        FROM delivered_order
    )
),
extras AS (
    SELECT order_id, pizza_id, row_index, topping_name
    FROM (
        SELECT * FROM (
            SELECT
                order_id, pizza_id, row_index,
                UNNEST(STRING_TO_ARRAY(extras, ',')) AS extras
            FROM order_row_index
        ) AS extras_temp
        WHERE extras NOT IN ('null', '')
    ) AS extrass
    JOIN pizza_runner.pizza_toppings ON extras::INT = topping_id
),
exclusions AS (
    SELECT
        order_id, pizza_id, row_index, topping_name
    FROM (
        SELECT * FROM (
            SELECT
                order_id, pizza_id, row_index,
                UNNEST(STRING_TO_ARRAY(exclusions, ',')) AS exclusions
            FROM order_row_index
        ) AS exclusions_temp
        WHERE exclusions NOT IN ('null', '')
    ) AS exclusionss
    JOIN pizza_runner.pizza_toppings ON exclusions::INT = topping_id
),
exclusions_toppings AS (
    SELECT
        row_index, pizza_id, topping_name,
        CONCAT(row_index,',',topping_name) AS row_index_toppings
    FROM exclusions
),
topping_unnest AS (
    SELECT
        row_index, pizza_id,
        UNNEST(STRING_TO_ARRAY(toppings, ',')) AS toppings
    FROM order_row_index ri
    JOIN pizza_runner.pizza_recipes USING(pizza_id)
    ORDER BY 1
),
order_array AS (
    SELECT
        row_index, pizza_id, toppings, topping_name,
        CONCAT(row_index, ',', topping_name) AS row_index_toppings
    FROM topping_unnest tu
    JOIN pizza_runner.pizza_toppings pt ON tu.toppings::INT = pt.topping_id
    ORDER BY row_index
),
ingredient AS (
    SELECT * FROM (
        SELECT
            row_index, pizza_id,
            SPLIT_PART(row_index_toppings, ',', 2) AS topping_name
        FROM order_array
        WHERE row_index_toppings NOT IN (
            SELECT row_index_toppings
            FROM exclusions_toppings
        )
        UNION ALL

        SELECT
            row_index, pizza_id, topping_name
        FROM extras
    ) AS pizza_ingd
    ORDER BY 1,2,3
)
SELECT
    topping_name,
    COUNT(*) AS ingredient_quantity
FROM ingredient
GROUP BY 1
ORDER BY 2 DESC;
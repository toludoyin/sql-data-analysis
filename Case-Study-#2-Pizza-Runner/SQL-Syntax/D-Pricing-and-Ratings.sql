-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
with delivered_order as (
    select order_id, pizza_id,
    case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation
    from pizza_runner.runner_orders
    join pizza_runner.customer_orders using(order_id)
),
pizza_price as (
    select order_id, pizza_id, pizza_name,
    (case when pizza_name = 'Meatlovers' then 12::int else 10::int end) as pizza_cost
    from delivered_order
    join pizza_runner.pizza_names using(pizza_id)
    where cancellation =0
)
select pizza_name, sum(pizza_cost) as total_pizza_cost
from pizza_price
group by 1;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- * Add cheese is $1 extra
with delivered_order as (
    select order_id, pizza_id,
    case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation,
    case when extras in ('null', '') then NULL else extras end as extras
    from pizza_runner.runner_orders
    join pizza_runner.customer_orders using(order_id)
),
pizza_price as (
    select order_id, pizza_id, extras, pizza_name,
    (case when pizza_name = 'Meatlovers' then 12::int else 10::int end) as pizza_amount
    from delivered_order
    join pizza_runner.pizza_names using(pizza_id)
    where cancellation =0
)
select pizza_name, sum(pizza_amount) + sum(extra_charges) as total_amount
from (
    select *, (case when num_of_extras is not null then num_of_extras *1::int else 0::int end) as extra_charges
    from (
        select *, extras, array_length(string_to_array(extras, ', '), 1) as num_of_extras
        from pizza_price
    ) as charges_on_extra
) as price_and_charges
group by 1;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- * customer_id
-- * order_id
-- * runner_id
-- * rating
-- * order_time
-- * pickup_time
-- * Time between order and pickup
-- * Delivery duration
-- * Average speed
-- * Total number of pizzas
with delivered_order as (
    select customer_id, order_id, runner_id, order_time,
    case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation,
    case when distance in ('null','') then NUll else split_part(distance, 'km', 1)::float end as distance,
    case when duration in ('null','') then NUll else split_part(duration, 'min', 1)::int end as duration_minute,
    case when pickup_time in ('null', '') then NULL else to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS') end as pickup_time
    from pizza_runner.runner_orders
    join pizza_runner.customer_orders using(order_id)
)
select customer_id, order_id, runner_id, order_time, pickup_time, --ratings,
extract(minute from (pickup_time - order_time)) as time_bet_order_and_pickup,  duration_minute,
avg(distance::float/(duration_minute::int/60.0)) as average_speed, total_num_of_pizzas
from (
    select customer_id, order_id, runner_id, pickup_time, duration_minute, distance, min(order_time) as order_time, count(*) as total_num_of_pizzas
    from delivered_order
    where cancellation =0
    group by 1,2,3,4,5,6
) as new_table
--join pizza_runner.order_ratings r using (order_id)
group by 1,2,3,4,5,6,7,9
order by 1;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
with delivered_order as (
    select order_id, pizza_id, runner_id,
    case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation,
    case when distance in ('null','') then NUll else split_part(distance, 'km', 1)::float end as distance
    from pizza_runner.runner_orders
    join pizza_runner.customer_orders using(order_id)
),
pizza_price as (
    select order_id, pizza_id, pizza_name, runner_id, distance,
    (case when pizza_name = 'Meatlovers' then 12::int else 10::int end) as pizza_cost
    from delivered_order
    join pizza_runner.pizza_names using(pizza_id)
    where cancellation =0
)
select
pizza_name,
sum(pizza_cost) as total_pizza_revenue,
sum(distance::float * 0.30) as delivery_cost,
(sum(pizza_cost) - sum(distance::float*0.30)) as gross_profit
from pizza_price
group by 1;
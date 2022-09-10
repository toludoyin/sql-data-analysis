-----------------------------------
--B. Runner and Customer Experience
-----------------------------------

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select
date_trunc('week', registration_date) as registratin_week,
concat('Week ', to_char(registration_date, 'ww')) as week_no,
count(distinct runner_id) as num_of_runners
from pizza_runner.runners
group by 1,2
order by 1;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select runner_id,
round(avg(arrival_time)) as avg_minute
from (
    select runner_id,
    extract(minute from (pickup_time - order_time)) as arrival_time
    from (
        select runner_id,
        order_time,
        case when pickup_time in ('null', '') then NULL else to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS') end as pickup_time,
        case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation
        from pizza_runner.runner_orders
        left join (
            select distinct order_id, order_time -- remove duplicate
            from pizza_runner.customer_orders
        ) as unique_orders
        using(order_id)
    ) as time_period
    where cancellation !=1
) as avg_minutes
group by 1
order by 1;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- ANSWER: YES, there is a relationship between the number of pizza and the time it takes to prepare it. The more the number of pizza ordered , the longer the time
select pizza_ordered,
round(avg(prepare_time_minute)) as avg_minute
from (
    select pizza_ordered,
    extract(minute from (pickup_time - order_time)) as prepare_time_minute
    from (
        select order_id,
        order_time, pizza_ordered,
        case when pickup_time in ('null', '') then NULL else to_timestamp(pickup_time, 'YYYY-MM-DD HH24:MI:SS') end as pickup_time,
        case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation
        from pizza_runner.runner_orders
        left join (
            select order_id, order_time,
            count(order_id) as pizza_ordered
            from pizza_runner.customer_orders
          group by 1,2
        ) as unique_orders using(order_id)
    ) as time_period
    where cancellation !=1
) as avg_minutes
group by 1
order by 1;

-- 4. What was the average distance travelled for each customer?
with distances as (
    select distinct order_id,
    customer_id,
    case when cancellation in ('null','') or cancellation is NUll then 0 else end as cancellation,
    case when distance in ('null','') then NUll else split_part(distance, 'km', 1) end as distance
    from pizza_runner.runner_orders
    left join pizza_runner.customer_orders using(order_id)
)
select
customer_id,
avg(distance::float) as avg_distance
from distances
where cancellation !=1
group by 1
order by 1;


-- 5. What was the difference between the longest and shortest delivery times for all orders?
with duration as (
    select distinct order_id,
    customer_id,
    case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation,
    case when duration in ('null','') then NUll else split_part(duration, 'min', 1)::int end as duration
    from pizza_runner.runner_orders
    left join pizza_runner.customer_orders using(order_id)
)
select
min(duration) as shortest_delivery,
max(duration) as longest_delivey,
(max(duration)-min(duration)) as difference_in_delivery
from duration
where cancellation != 1
order by 1;


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
with runners as (
    select distinct runner_id, order_id,
    case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation,
    case when distance in ('null','') then NUll else split_part(distance, 'km', 1)::float end as distance,
    case when duration in ('null','') then NUll else split_part(duration, 'min', 1)::int end as duration_minute
    from pizza_runner.runner_orders
)
select
runner_id, order_id,
avg(distance/(duration_minute/60.0)) as speed_km_per_hr
from runners
where cancellation != 1
group by 1,2
order by 1;

-- 7. What is the successful delivery percentage for each runner?
with runners as (
    select distinct runner_id, order_id,
    case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation,
    case when distance in ('null','') then NUll else split_part(distance, 'km', 1)::float end as distance,
    case when duration in ('null','') then NUll else split_part(duration, 'min', 1)::int end as duration_minute
    from pizza_runner.runner_orders
)
select
runner_id,
count(case when cancellation = 0 then cancellation end) as successful_delivery,
count(*) as total_delivery,
(count(case when cancellation = 0 then cancellation end))/ count(*)::float as successful_delivery_percent
from runners
group by 1
order by 1

------------------------------
-- CASE STUDY A. PIZZA METRICS
------------------------------
--Tools used: PostgreSQL

-- 1. How many pizzas were ordered?
select
count(pizza_id) as total_pizzas_ordered
from pizza_runner.customer_orders;

-- 2. How many unique customer orders were made?
select
count(distinct order_id) as unique_customers
from pizza_runner.customer_orders;

-- 3. How many successful orders were delivered by each runner?
select runner_id,
count(order_id) as  num_of_orders_delivered
from (
    select *,
    case when Cancellation = 'null'
    or Cancellation is null
    or Cancellation = '' then 0 else 1 end as cancellation2
    from pizza_runner.runner_orders
) as successful_orders
where cancellation2 = 0
group by 1
order by 1;

-- 4. How many of each type of pizza was delivered?
with pizza_types as (
    select *,
    case when Cancellation = 'null'
    or Cancellation is null
    or Cancellation = '' then 0 else 1 end as cancellation2
    from pizza_runner.runner_orders ro
    join pizza_runner.customer_orders co using(order_id)
left join pizza_runner.pizza_names pn on co.pizza_id = pn.pizza_id
)
select
pizza_name,
count(order_id) as num_of_orders
from pizza_types
where cancellation2 = 0
group by 1
order by 1;

-- 5.How many Vegetarian and Meatlovers were ordered by each customer?
select
customer_id,
coalesce(count(case when pizza_name='Meatlovers' then order_id end),0) as Meatlovers,
coalesce(count(case when pizza_name='Vegetarian' then order_id end),0) as Vegetarian
from pizza_runner.runner_orders ro
join pizza_runner.customer_orders co using(order_id)
left join pizza_runner.pizza_names pn on co.pizza_id = pn.pizza_id
group by 1
order by 1;

-- 6. What was the maximum number of pizzas delivered in a single order?
select order_id,
count(pizza_id) as num_of_pizzas_delivered
from pizza_runner.customer_orders
group by 1
order by 2 desc;


-- 7 and 8
with cleaned_data as (
    select *,
    case when exclusions in ('null', '') or exclusions is null then '0'
    else exclusions end as exclusion,
    case when extras in ('null', '') or extras is null then '0'
    else extras end as extra
    from pizza_runner.customer_orders
    where order_id in
    (
        select distinct order_id from
        (
            select *,
            case when Cancellation is null
            or Cancellation in('null', '') then 0 else 1 end as cancellation2
            from pizza_runner.runner_orders
        ) as successful_pizza
        where cancellation2 = 0
    )
),
create_change_col as (
    select *,
    case when exclusion = '0' and extra = '0' then 0 else 1 end as change
    from cleaned_data
),
made_changes as (
    select
    customer_id,
    count(order_id) filter (where change::int = 0) as pizza_no_changes,
    count(order_id) filter (where change::int > 0) as pizza_changes
    from create_change_col
    group by 1
    order by 1
),   -- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
made_both_change as (
    select customer_id,
    count(order_id) filter (where exclu_change::int > 0 and extra_change::int > 0) as exclusion_extra
    from (
        select *,
        case when exclusion = '0' then 0 else 1 end as exclu_change,
        case when extra = '0' then 0 else 1 end as extra_change
        from create_change_col
        ) as made_both_changes
    group by 1
    order by 1
)       --8. How many pizzas were delivered that had both exclusions and extras?
select *
-- from made_changes       -- 7.
from made_both_change;      -- 8.


-- 9. What was the total volume of pizzas ordered for each hour of the day?
select
extract(hour from order_time) as hour_of_day,
count(order_id) as num_of_order
from pizza_runner.customer_orders
group by 1;


-- 10. What was the volume of orders for each day of the week?
select
to_char(order_time, 'Day') as day_of_week,
extract(dow from order_time) as week_day,
count(order_id) as num_of_orders
from pizza_runner.customer_orders
group by 1,2
order by 3 desc;
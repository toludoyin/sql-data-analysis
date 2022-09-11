----------------------------
--C. INGREDIENT OPTIMIZATION
----------------------------

-- 1. What are the standard ingredients for each pizza?
with topping_nest as (
    select pizza_id,
    unnest(string_to_array(toppings, ','))::int as topping_id
    from pizza_runner.pizza_recipes
),
ingredient as (
    select * from topping_nest
    join pizza_runner.pizza_toppings using(topping_id)
    left join pizza_runner.pizza_names using(pizza_id)
)
select
pizza_name,
string_agg(topping_name, ',') as standard_ingredient
from ingredient
group by 1;

-- 2. What was the most commonly added extra?
with pizza_topping as (
    select pizza_id,
    unnest(string_to_array(extras, ','))::int as topping_id
    from (
        select pizza_id,
        case when extras in ('null', '') then NULL else extras end as extras
        from pizza_runner.customer_orders
    ) as pizza_extra
)
select
topping_name,
count(pizza_id) as num_of_toppings
from pizza_topping
join pizza_runner.pizza_toppings using(topping_id)
group by 1
order by 2 desc
limit 1;

-- 3. What was the most common exclusion?
with pizza_topping as (
    select pizza_id,
    unnest(string_to_array(exclusions, ','))::int as topping_id
    from (
        select pizza_id,
        case when exclusions in ('null', '') then NULL else exclusions end as exclusions
        from pizza_runner.customer_orders
    ) as pizza_exclusions
)
select
topping_name,
count(pizza_id) as num_of_toppings
from pizza_topping
join pizza_runner.pizza_toppings using(topping_id)
group by 1
order by 2 desc
limit 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- * Meat Lovers
-- * Meat Lovers - Exclude Beef
-- * Meat Lovers - Extra Bacon
-- * Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
with row_indexx as (
    select *,
    row_number() over() as row_index
    from pizza_runner.customer_orders
),
extras as (
    select order_id, pizza_id, row_index, topping_name
    from (
        select *
        from (
            select order_id, pizza_id, row_index,
            unnest(string_to_array(extras, ',')) as extras
            from row_indexx
        ) as extras_temp
        where extras not in ('null', '')
    ) as extrass
    join pizza_runner.pizza_toppings on extras::int = topping_id
),
exclusions as (
    select order_id, pizza_id, row_index, topping_name
    from (
        select *
        from (
            select order_id, pizza_id, row_index,
            unnest(string_to_array(exclusions, ',')) as exclusions
            from row_indexx
        ) as exclusions_temp
        where exclusions not in ('null', '')
    ) as exclusionss
    join pizza_runner.pizza_toppings on exclusions::int = topping_id
),
extra_toppings as (
    select row_index, string_agg(topping_name, ', ') as extra
    from extras
    group by 1
),
exclusions_toppings as (
    select row_index, string_agg(topping_name, ', ') as exclusion
    from exclusions
    group by 1
)
select concat(pizza_name,
       case when e.extra is null then '' else '- Exclude ' end, e.extra,
       case when t.exclusion is null then '' else ' - Exclude ' end,
       t.exclusion) as pizza_ordered
from row_indexx ri
left join extra_toppings e using(row_index)
left join exclusions_toppings t using(row_index)
join pizza_runner.pizza_names using(pizza_id)
where pizza_name = 'Meatlovers';

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
with row_indexx as (
    select *,
    row_number() over() as row_index
    from pizza_runner.customer_orders
),
extras as (
    select order_id, pizza_id, row_index, topping_name
    from (
        select *
        from (
            select order_id, pizza_id, row_index,
            unnest(string_to_array(extras, ',')) as extras
            from row_indexx
        ) as extras_temp
        where extras not in ('null', '')
    ) as extrass
    join pizza_runner.pizza_toppings on extras::int = topping_id
),
exclusions as (
    select order_id, pizza_id, row_index, topping_name
    from (
        select *
        from (
            select order_id, pizza_id, row_index,
            unnest(string_to_array(exclusions, ',')) as exclusions
            from row_indexx
        ) as exclusions_temp
        where exclusions not in ('null', '')
    ) as exclusionss
    join pizza_runner.pizza_toppings on exclusions::int = topping_id
),
exclusions_toppings as (
    select row_index, pizza_id, topping_name,
    concat(row_index,',',topping_name) AS row_index_toppings
    from exclusions
),
topping_unnest as (
    select row_index, pizza_id,
    unnest(string_to_array(toppings, ',')) as toppings
    from row_indexx ri
    join pizza_runner.pizza_recipes using(pizza_id)
    order by 1
),
order_array as (
    select row_index, pizza_id, toppings, topping_name,
    concat(row_index, ',', topping_name) as row_index_toppings
    from topping_unnest tu
    join pizza_runner.pizza_toppings pt on tu.toppings::int = pt.topping_id
    order by row_index
),
ingredient as (
    select * from (
        select row_index, pizza_id,
        split_part(row_index_toppings, ',', 2) as topping_name
        from  order_array
        where row_index_toppings not in (
            select row_index_toppings
            from exclusions_toppings
            )
union all

select row_index, pizza_id, topping_name
from extras
    ) as pizza_ingd
    order by 1,2,3
)
select
concat(pizza_name, ': ', topping_name) as pizza_ingredient_list
from (
    select row_index, pizza_id,
    string_agg(case when multiple_ingrd = 1 then topping_name else
    concat(multiple_ingrd, 'x', topping_name) end, ', ') as topping_name
    from (
        select row_index, pizza_id, topping_name, count(*) as multiple_ingrd
        from ingredient
        group by 1,2,3
    ) as ingd_count
    group by 1,2
) as pizza_ingredient
join pizza_runner. pizza_names using(pizza_id);

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with delivered_order as (
    select order_id
    from (
        select order_id,
        case when cancellation in ('null','') or cancellation is NUll then 0 else 1 end as cancellation
        from pizza_runner.runner_orders
        join pizza_runner.customer_orders using(order_id)
    ) as orders
    where cancellation =0
),
order_row_index as (
    select *,
    row_number() over() as row_index
    from pizza_runner.customer_orders
    where order_id in (
        select order_id
        from delivered_order
        )
),
extras as (
    select order_id, pizza_id, row_index, topping_name
    from (
        select *
        from (
            select order_id, pizza_id, row_index,
            unnest(string_to_array(extras, ',')) as extras
            from order_row_index
        ) as extras_temp
        where extras not in ('null', '')
    ) as extrass
    join pizza_runner.pizza_toppings on extras::int = topping_id
),
exclusions as (
    select order_id, pizza_id, row_index, topping_name
    from (
        select *
        from (
            select order_id, pizza_id, row_index,
            unnest(string_to_array(exclusions, ',')) as exclusions
            from order_row_index
        ) as exclusions_temp
        where exclusions not in ('null', '')
    ) as exclusionss
    join pizza_runner.pizza_toppings on exclusions::int = topping_id
),
exclusions_toppings as (
    select row_index, pizza_id, topping_name,
    concat(row_index,',',topping_name) AS row_index_toppings
    from exclusions
),
topping_unnest as (
    select row_index, pizza_id,
    unnest(string_to_array(toppings, ',')) as toppings
    from order_row_index ri
    join pizza_runner.pizza_recipes using(pizza_id)
    order by 1
),
order_array as (
    select row_index, pizza_id, toppings, topping_name,
    concat(row_index, ',', topping_name) as row_index_toppings
    from topping_unnest tu
    join pizza_runner.pizza_toppings pt on tu.toppings::int = pt.topping_id
    order by row_index
),
ingredient as (
    select * from (
        select row_index, pizza_id,
        split_part(row_index_toppings, ',', 2) as topping_name
        from  order_array
        where row_index_toppings not in (
            select row_index_toppings
            from exclusions_toppings
            )
union all

select row_index, pizza_id, topping_name
from extras
    ) as pizza_ingd
    order by 1,2,3
)
select
topping_name, count(*) as ingredient_quantity
from ingredient
group by 1
order by 2 desc;
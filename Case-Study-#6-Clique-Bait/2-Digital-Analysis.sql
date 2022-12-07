-- Using the available datasets - answer the following questions using a single query for each one:

-- How many users are there?
select count(distinct user_id) from clique_bait.users;

-- How many cookies does each user have on average?
select user_id, round(avg(no_of_cookies)) as avg_cookie
from (
    select distinct user_id, count(cookie_id) as no_of_cookies
    from clique_bait.users
    group by 1
) as cookies
group by 1
order by 1;

-- What is the unique number of visits by all users per month?
select
    date_trunc('month', event_time) as event_month, user_id,
    count(distinct visit_id) as num_of_visit
from clique_bait.events
left join clique_bait.users using(cookie_id)
group by 1,2;

-- What is the number of events for each event type?
select event_name, count(event_type) as num_event_type
from clique_bait.events
left join clique_bait.event_identifier using(event_type)
group by 1
order by 2 desc;

-- What is the percentage of visits which have a purchase event?
select
    count(event_type) filter(where event_name = 'Purchase') as purchase_event,
    count(event_type) as total_event_type,
    round((count(event_type) filter(where event_name = 'Purchase')/count(event_type)::numeric)*100,2) as pertcg
from clique_bait.events
left join clique_bait.event_identifier using(event_type);

-- What is the percentage of visits which view the checkout page but do not have a purchase event?
select
    count(distinct visit_id) filter(where page_name='Checkout' and event_name != 'Purchase') as checkout_no_purchase,
    count(distinct visit_id) as total_visit,
    round((count(distinct visit_id) filter(where page_name='Checkout' and event_name != 'Purchase')/count(distinct visit_id)::numeric)*100,2) as pertcg
from clique_bait.events
left join clique_bait.event_identifier using(event_type)
left join clique_bait.page_hierarchy using(page_id);

-- What are the top 3 pages by number of views?
select page_name, count(*) as num_of_views
from clique_bait.events
left join clique_bait.event_identifier using(event_type)
left join clique_bait.page_hierarchy using(page_id)
where event_name = 'Page View'
group by 1
order by 2 desc
limit 3;

-- What is the number of views and cart adds for each product category?
select
    product_category,
    count(*) filter(where event_name = 'Page View') as page_veiws,
    count(*) filter(where event_name = 'Add to Cart') as add_cart
from clique_bait.events
left join clique_bait.event_identifier using(event_type)
left join clique_bait.page_hierarchy using(page_id)
where product_category is not null
group by 1
order by 2,3 desc

-- What are the top 3 products by purchases?
select page_name, count(*) as num_of_product_pages
from clique_bait.events
left join clique_bait.event_identifier using(event_type)
left join clique_bait.page_hierarchy using(page_id)
where event_name = 'Purchase'
group by 1
order by 2 desc
limit 3;
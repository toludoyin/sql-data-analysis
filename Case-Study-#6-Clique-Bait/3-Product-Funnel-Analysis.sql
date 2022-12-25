/**
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
**/

with purchase as (
  select visit_id
  from clique_bait.events e
  where page_id = 13
),
abandoned as (
  select visit_id
  from clique_bait.events e
  where page_id = 12 and page_id <> 13
  )
  select
    product_id, page_name,
    count(visit_id) filter(where event_name = 'Page View') as total_page_views,
    count(visit_id) filter(where event_name = 'Add to Cart') as total_cart_adds,
    count(case when visit_id in (select visit_id from purchase) and event_type not in (1,4,5) then 1 end) as product_purchase,
 count(case when event_name = 'Add to Cart' and visit_id in (select visit_id from abandoned) then 1 end) as abandoned_add_to_cart                           from clique_bait.events e
  left join clique_bait.page_hierarchy ph using(page_id)
  left join clique_bait.event_identifier using(event_type)
  where product_id is not null
  group by 1,2;

/**
Use your 2 new output tables - answer the following questions:

Which product had the most views, cart adds and purchases?
Which product was most likely to be abandoned?
Which product had the highest view to purchase percentage?
What is the average conversion rate from view to cart add?
What is the average conversion rate from cart add to purchase?

Answers:
Lobster: had the most veiws
**/

with purchase as (
    select visit_id
    from clique_bait.events e
    where page_id = 13
),
abandoned as (
    select visit_id
    from clique_bait.events e
    where page_id = 12 and page_id <> 13
),
summary as (
    select
    product_id, page_name,
    count(visit_id) filter(where event_name = 'Page View') as total_page_views,
    count(visit_id) filter(where event_name = 'Add to Cart') as total_cart_adds,
    count(case when visit_id in (select visit_id from purchase) and event_type not in (1,4,5) then 1 end) as product_purchase,
    count(case when event_name = 'Add to Cart' and visit_id in (select visit_id from abandoned) then 1 end) as abandoned_add_to_cart
    from clique_bait.events e
    left join clique_bait.page_hierarchy ph using(page_id)
    left join clique_bait.event_identifier using(event_type)
    where product_id is not null
    group by 1,2
)
select
    round(avg(cart_add_to_views),2) as avg_views_to_cart,
    round(avg(purchase_from_add_to_cart),2) as avg_views_to_cart
    from (
        select *,
        round((total_cart_adds / total_page_views::numeric)*100,2) as cart_add_to_views,
        round((product_purchase / total_page_views::numeric)*100,2) as purchase_to_views,
        (product_purchase / total_cart_adds::numeric)*100 as purchase_from_add_to_cart
        from summary
        order by 7 desc
) as tmp;
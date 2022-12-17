/**
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
**/

select page_name, count(*) as count
from clique_bait.events
join clique_bait.event_identifier using(event_type)
left join clique_bait.page_hierarchy using(page_id)
where event_name = 'Page View'
group by 1
order by 2 desc
limit 10;

/**
Use your 2 new output tables - answer the following questions:

Which product had the most views, cart adds and purchases?
Which product was most likely to be abandoned?
Which product had the highest view to purchase percentage?
What is the average conversion rate from view to cart add?
What is the average conversion rate from cart add to purchase?
**/
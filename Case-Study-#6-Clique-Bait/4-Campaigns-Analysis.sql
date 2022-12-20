/**
Generate a table that has 1 single row for every unique visit_id record and has the following columns:

user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.
**/

select tmp.*, campaign_name
from (
  select
    user_id,
    visit_id,
    min(event_time) as visit_start_time,
    count(visit_id) filter(where event_name = 'Page View') as page_views,
    count(visit_id) filter(where event_name = 'Add to Cart') as cart_adds,
    max(case when event_name = 'Purchase' then 1 else 0 end) as purchase_flag,
    count(visit_id) filter(where event_name = 'Ad Impression') as impressions,
    count(visit_id) filter(where event_name = 'Ad Click') as clicks,
    string_agg(case when event_name = 'Add to Cart' then product_id::text end, ',' order by product_id) as cart_products
  from clique_bait.events e
  left join clique_bait.users u on e.cookie_id = u.cookie_id
  and e.event_time::date >= u.start_date
  left join clique_bait.page_hierarchy ph using(page_id)
  left join clique_bait.event_identifier ei on e.event_type = 		ei.event_type
  group by 1,2
  ) as tmp
left join clique_bait.campaign_identifier ci on tmp.visit_start_time >= ci.start_date
and tmp.visit_start_time <= ci.end_date
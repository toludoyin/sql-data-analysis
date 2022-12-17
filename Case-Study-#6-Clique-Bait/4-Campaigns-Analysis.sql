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

Some ideas you might want to investigate further include:

Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
Does clicking on an impression lead to higher purchase rates?
What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
What metrics can you use to quantify the success or failure of each campaign compared to eachother?
**/

select
user_id,
visit_id
min(event_time) as visit_start_time,
max(event_time) as visit_end_time,
count(visit_id) filter(where event_name = 'Page View') as page_views,
count(visit_id) filter(where event_name = 'Add to Cart') as cart_adds,
purchase,
campaign_name,
count(visit_id) filter(where event_name = 'Ad Impression') as
count(visit_id) filter(where event_name = 'Ad Click') as click
impression
from 
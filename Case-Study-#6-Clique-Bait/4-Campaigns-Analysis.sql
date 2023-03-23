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

SELECT tmp.*, campaign_name
FROM (
    SELECT
        user_id,
        visit_id,
        MIN(event_time) AS visit_start_time,
        COUNT(visit_id) FILTER(WHERE event_name = 'Page View') AS page_views,
        COUNT(visit_id) FILTER(WHERE event_name = 'Add to Cart') AS cart_adds,
        MAX(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 end) AS purchase_flag,
        COUNT(visit_id) FILTER(WHERE event_name = 'Ad Impression') AS impressions,
        COUNT(visit_id) FILTER(WHERE event_name = 'Ad Click') AS clicks,
        STRING_AGG(CASE WHEN event_name = 'Add to Cart' THEN product_id::TEXT END, ',' ORDER BY product_id) AS cart_products
  FROM clique_bait.events e
  LEFT JOIN clique_bait.users u ON e.cookie_id = u.cookie_id
            AND e.event_time::DATE >= u.start_date
  LEFT JOIN clique_bait.page_hierarchy ph USING(page_id)
  LEFT JOIN clique_bait.event_identifier ei ON e.event_type = ei.event_type
  GROUP BY 1,2
) AS tmp
LEFT JOIN clique_bait.campaign_identifier ci ON tmp.visit_start_time >= ci.start_date
          AND tmp.visit_start_time <= ci.end_date
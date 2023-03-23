-- Using the available datasets - answer the following questions using a single query for each one:

-- How many users are there?
SELECT
    COUNT(DISTINCT user_id) AS num_of_users
FROM clique_bait.users;

-- How many cookies does each user have on average?
SELECT
    user_id,
    ROUND(AVG(no_of_cookies)) AS avg_cookie
FROM (
    SELECT
        DISTINCT user_id,
        COUNT(cookie_id) AS no_of_cookies
    FROM clique_bait.users
    GROUP BY 1
) AS cookies
GROUP BY 1
ORDER BY 1;

-- What is the unique number of visits by all users per month?
SELECT
    DATE_TRUNC('month', event_time) AS event_month, user_id,
    COUNT(DISTINCT visit_id) AS num_of_visit
FROM clique_bait.events
LEFT JOIN clique_bait.users USING(cookie_id)
GROUP BY 1,2;

-- What is the number of events for each event type?
SELECT
    event_name,
    COUNT(event_type) AS num_event_type
FROM clique_bait.events
LEFT JOIN clique_bait.event_identifier USING(event_type)
GROUP BY 1
ORDER BY 2 DESC;

-- What is the percentage of visits which have a purchase event?
SELECT
    COUNT(event_type) FILTER(WHERE event_name = 'Purchase') AS purchase_event,
    COUNT(event_type) AS total_event_type,
    ROUND((COUNT(event_type) FILTER(WHERE event_name = 'Purchase')/COUNT(event_type)::NUMERIC)*100,2) AS pertcg
FROM clique_bait.events
LEFT JOIN clique_bait.event_identifier USING(event_type);

-- What is the percentage of visits which view the checkout page but do not have a purchase event?
SELECT
    COUNT(DISTINCT visit_id) FILTER(WHERE page_name='Checkout' AND event_name != 'Purchase') AS checkout_no_purchase,
    COUNT(DISTINCT visit_id) AS total_visit,
    ROUND((COUNT(DISTINCT visit_id) FILTER(WHERE page_name='Checkout' AND event_name != 'Purchase')/COUNT(DISTINCT visit_id)::NUMERIC)*100,2) AS pertcg
FROM clique_bait.events
LEFT JOIN clique_bait.event_identifier USING(event_type)
LEFT JOIN clique_bait.page_hierarchy USING(page_id);

-- What are the top 3 pages by number of views?
SELECT
    page_name,
    COUNT(*) AS num_of_views
FROM clique_bait.events
LEFT JOIN clique_bait.event_identifier USING(event_type)
LEFT JOIN clique_bait.page_hierarchy USING(page_id)
WHERE event_name = 'Page View'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- What is the number of views and cart adds for each product category?
SELECT
    product_category,
    COUNT(*) FILTER(WHERE event_name = 'Page View') AS page_veiws,
    COUNT(*) FILTER(WHERE event_name = 'Add to Cart') AS add_cart
FROM clique_bait.events
LEFT JOIN clique_bait.event_identifier USING(event_type)
LEFT JOIN clique_bait.page_hierarchy USING(page_id)
WHERE product_category IS NOT NULL
GROUP BY 1
ORDER BY 2,3 DESC;

-- What are the top 3 products by purchases?
WITH purchase AS (
    SELECT visit_id
    FROM clique_bait.events
    LEFT JOIN clique_bait.event_identifier USING(event_type)
    WHERE event_name = 'Purchase'
)
SELECT
    product_id, page_name,
    COUNT(*) AS num_of_purchase
FROM clique_bait.events
LEFT JOIN clique_bait.page_hierarchy USING(page_id)
JOIN purchase USING(visit_id)
WHERE product_id IS NOT NULL
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 3;
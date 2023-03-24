/**
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
Additionally, create another table which further aggregates the data for the
above points but this time for each product category instead of individual products.
**/

WITH purchase AS (
    SELECT visit_id
    FROM clique_bait.events e
    WHERE page_id = 13
),
abandoned AS (
    SELECT visit_id
    FROM clique_bait.events e
    WHERE page_id = 12
    AND page_id <> 13
)
SELECT
    product_id, page_name,
    COUNT(visit_id) FILTER(WHERE event_name = 'Page View') AS total_page_views,
    COUNT(visit_id) FILTER(WHERE event_name = 'Add to Cart') AS total_cart_adds,
    COUNT(CASE WHEN visit_id IN (
        SELECT visit_id
        FROM purchase)
    AND event_type NOT IN (1,4,5) THEN 1 END) AS product_purchase,
    COUNT(CASE WHEN event_name = 'Add to Cart' AND visit_id IN (
        SELECT visit_id
        FROM abandoned
    ) THEN 1 END) AS abandoned_add_to_cart
FROM clique_bait.events e
LEFT JOIN clique_bait.page_hierarchy ph USING(page_id)
LEFT JOIN clique_bait.event_identifier USING(event_type)
WHERE product_id IS NOT NULL
GROUP BY 1,2;

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

WITH purchase AS (
    SELECT visit_id
    FROM clique_bait.events e
    WHERE page_id = 13
),
abandoned AS (
    SELECT visit_id
    FROM clique_bait.events e
    WHERE page_id = 12
    AND page_id <> 13
),
summary AS (
    SELECT
        product_id, page_name,
        COUNT(visit_id) FILTER(WHERE event_name = 'Page View') AS total_page_views,
        COUNT(visit_id) FILTER(WHERE event_name = 'Add to Cart') AS total_cart_adds,
        COUNT(CASE WHEN visit_id IN (
            SELECT visit_id
            FROM purchase
        ) AND event_type NOT IN (1,4,5) THEN 1 END) AS product_purchase,
        COUNT(CASE WHEN event_name = 'Add to Cart' AND visit_id IN (
            SELECT visit_id
            FROM abandoned
        ) THEN 1 END) AS abandoned_add_to_cart
    FROM clique_bait.events e
    LEFT JOIN clique_bait.page_hierarchy ph USING(page_id)
    LEFT JOIN clique_bait.event_identifier USING(event_type)
    WHERE product_id IS NOT NULL
    GROUP BY 1,2
)
SELECT
    ROUND(AVG(cart_add_to_views),2) AS avg_views_to_cart,
    ROUND(AVG(purchase_from_add_to_cart),2) AS avg_views_to_cart
FROM (
    SELECT *,
        ROUND((total_cart_adds / total_page_views::NUMERIC)*100,2) AS cart_add_to_views,
        ROUND((product_purchase / total_page_views::NUMERIC)*100,2) AS purchase_to_views,
        (product_purchase / total_cart_adds::NUMERIC)*100 AS purchase_from_add_to_cart
    FROM summary
    ORDER BY 7 DESC
) AS tmp;
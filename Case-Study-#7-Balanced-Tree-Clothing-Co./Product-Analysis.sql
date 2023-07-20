-- What are the top 3 products by total revenue before discount?
SELECT
    product_name, SUM(bts.price * qty) AS revenue
FROM balanced_tree.sales bts
JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- What is the total quantity, revenue and discount for each segment?
SELECT
    segment_name,
    SUM(bts.price * qty) AS revenue,
    SUM(bts.price * qty * discount)/100 AS discount,
    SUM(qty) AS quantity
FROM balanced_tree.sales bts
JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- What is the top selling product for each segment?
WITH rank_segment AS (
    SELECT
        segment_name,
        product_name,
        SUM(bts.price * qty) AS revenue,
        ROW_NUMBER() OVER(PARTITION BY segment_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
    segment_name,
    product_name,
    revenue
FROM rank_segment
WHERE rn = 1;

-- What is the total quantity, revenue and discount for each category?
SELECT
    category_name,
    SUM(bts.price * qty) AS revenue,
    SUM(bts.price * qty * discount)/100 AS discount,
    SUM(qty) AS quantity
FROM balanced_tree.sales bts
JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
GROUP BY 1;

-- What is the top selling product for each category?
WITH rank_category AS (
    SELECT
        category_name,
        product_name,
        SUM(bts.price * qty) AS revenue,
        ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
    category_name,
    product_name,
    revenue
FROM rank_category
WHERE rn = 1;

-- What is the percentage split of revenue by product for each segment?
WITH rank_category AS (
    SELECT
        category_name,
        product_name,
        SUM(bts.price * qty) AS revenue,
        ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
    category_name,
    product_name,
    revenue,
    ROUND(revenue/SUM(revenue)OVER()*100,2) AS revenue_perctg
FROM rank_category
WHERE rn = 1
GROUP BY 1,2,revenue;

-- What is the percentage split of revenue by segment for each category?
WITH rank_category AS (
    SELECT
        category_name,
        product_name,
        SUM(bts.price * qty) AS revenue,
        ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
    category_name,
    product_name,
    revenue,
    ROUND(revenue/SUM(revenue)OVER()*100,2) AS revenue_perctg
FROM rank_category
WHERE rn = 1
GROUP BY 1,2,revenue;

-- What is the percentage split of total revenue by category?
WITH rank_segment AS (
    SELECT
        segment_name,
        product_name,
        SUM(bts.price * qty) AS revenue,
        ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
    segment_name,
    product_name,
    revenue,
    ROUND(revenue/SUM(revenue)OVER()*100,2) AS revenue_perctg
FROM rank_category
WHERE rn = 1
GROUP BY 1,2,revenue;

-- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH product_txn AS (
    SELECT
    product_name,
    COUNT(DISTINCT txn_id) AS num_of_txn
    FROM balanced_tree.sales bts
    JOIN balanced_tree.product_details pt ON pt.product_id = bts.prod_id
    GROUP BY 1
),
total_txn AS (
    SELECT
    COUNT(DISTINCT txn_id) AS total_of_txn
    FROM balanced_tree.sales bts
)
SELECT
product_name,
ROUND((num_of_txn::NUMERIC/total_of_txn) *100,2) AS total_penetration
FROM product_txn, total_txn
ORDER BY 2 DESC;

-- What is the most common combination of at least 1 quantity of any 3 productsin a 1 single transaction?

/* While trying to solve this was chanllenging, i came across https://github.com/iweld/8-Week-SQL-Challenge solution which help me understand the logic to solve the problem using combinatorics math approach . Interpretation: i.e the most purchased 3 product combination.
*/
WITH product_txn AS (
    SELECT
    product_name,
    txn_id
    FROM balanced_tree.sales bts
    JOIN balanced_tree.product_details pt on pt.product_id = bts.prod_id
)
SELECT * FROM (
    SELECT
        p.product_name AS product1,
        p1.product_name AS product2,
        p2.product_name AS product3,
        COUNT(*) AS num_of_time_bought_together,
        ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS rank_row
    FROM product_txn AS p
    JOIN product_txn AS p1 ON p1.txn_id = p.txn_id -- used a self join on table 1 and 2
    AND p.product_name != p1.product_name  --remove duplicate
    AND p.product_name < p1.product_name
    JOIN product_txn AS p2 ON p2.txn_id = p.txn_id -- used a self join on table 1 and 3
    AND p.product_name != p1.product_name
    AND p1.product_name != p2.product_name
    AND p1.product_name < p2.product_name
    AND p1.product_name < p2.product_name
    GROUP BY 1,2,3
    ORDER BY 5
) AS conbination
WHERE rank_row = 1;
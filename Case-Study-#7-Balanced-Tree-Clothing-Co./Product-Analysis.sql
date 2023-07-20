-- What are the top 3 products by total revenue before discount?
SELECT product_name, SUM(bts.price * qty) AS revenue
FROM balanced_tree.sales bts
join balanced_tree.product_details pt on pt.product_id = bts.prod_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- What is the total quantity, revenue and discount for each segment?
SELECT segment_name,
SUM(bts.price * qty) AS revenue,
SUM(bts.price * qty * discount)/100 AS discount,
SUM(qty) AS quantity
FROM balanced_tree.sales bts
join balanced_tree.product_details pt on pt.product_id = bts.prod_id
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
    join balanced_tree.product_details pt on pt.product_id = bts.prod_id
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
join balanced_tree.product_details pt on pt.product_id = bts.prod_id
GROUP BY 1;

-- What is the top selling product for each category?
WITH rank_category AS (
    SELECT
    category_name,
    product_name,
    SUM(bts.price * qty) AS revenue,
    ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    join balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
category_name,
product_name,
revenue
FROM rank_category
WHERE rn = 1

-- What is the percentage split of revenue by product for each segment?
WITH rank_category AS (
    SELECT
    category_name,
    product_name,
    SUM(bts.price * qty) AS revenue,
    ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    join balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
    category_name,
    product_name,
    revenue,
    ROUND(revenue/SUM(revenue)OVER()*100,2) AS revenue_perctg
FROM rank_category
WHERE rn = 1
GROUP BY 1,2,revenue

-- What is the percentage split of revenue by segment for each category?
WITH rank_category AS (
    SELECT
    category_name,
    product_name,
    SUM(bts.price * qty) AS revenue,
    ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
    FROM balanced_tree.sales bts
    join balanced_tree.product_details pt on pt.product_id = bts.prod_id
    GROUP BY 1,2
)
SELECT
    category_name,
    product_name,
    revenue,
    ROUND(revenue/SUM(revenue)OVER()*100,2) AS revenue_perctg
FROM rank_category
WHERE rn = 1
GROUP BY 1,2,revenue

-- What is the percentage split of total revenue by category?
WITH rank_segment AS (
  SELECT
segment_name,
product_name,
SUM(bts.price * qty) AS revenue,
ROW_NUMBER() OVER(PARTITION BY category_name ORDER BY SUM(bts.price * qty) DESC) AS rn
FROM balanced_tree.sales bts
join balanced_tree.product_details pt on pt.product_id = bts.prod_id
GROUP BY 1,2
  )
  SELECT
segment_name,
product_name,
revenue,
ROUND(revenue/SUM(revenue)OVER()*100,2) AS revenue_perctg
FROM rank_category
  WHERE rn = 1
  GROUP BY 1,2,revenue

-- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

-- What is the most common combination of at least 1 quantity of any 3 productsin a 1 single transaction?
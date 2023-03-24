------------------------------
-- CASE STUDY 1 DANNY'S DINER
------------------------------
--Tools used: PostgreSQL

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
    DISTINCT s.customer_id,
    SUM(m.price) AS total_amount
FROM dannys_diner.sales s
JOIN dannys_diner.menu m USING(product_id)
GROUP BY 1
ORDER BY 1;

-- 2. How many days has each customer visited the restaurant?
SELECT
    DISTINCT s.customer_id,
    COUNT(DISTINCT s.order_date) AS num_of_visit_days
FROM dannys_diner.sales s
JOIN dannys_diner.menu m USING(product_id)
GROUP BY 1;

-- 3. What was the first item from the menu purchased by each customer?
SELECT
    order_date,
    customer_id,
    product_name
FROM (
    SELECT
        order_date::DATE,
        customer_id,
        product_name,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date::DATE) AS row_num
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m USING(product_id)
    ORDER BY order_date::DATE, customer_id
) AS first_order
WHERE row_num = 1;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    m.product_name,
    SUM(m.price) AS total_price,
    COUNT(*) AS num_of_times_purchase
FROM dannys_diner.sales s
JOIN dannys_diner.menu m USING(product_id)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SELECT
    customer_id,
    product_name,
    num_of_times_product_ordered
FROM (
    SELECT
        customer_id,
        product_name,
        COUNT(product_name) AS num_of_times_product_ordered,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(product_name) DESC) AS row_num
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m USING(product_id)
    GROUP BY 1,2
    ORDER BY 1
) AS popular
WHERE row_num = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT
    customer_id,
    product_name,
    num_of_times_product_ordered
FROM (
    SELECT
        customer_id,
        product_name,
        join_date,
        s.order_date,
        COUNT(product_name) AS num_of_times_product_ordered,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS row_num
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m USING(product_id)
    LEFT JOIN  dannys_diner.members me USING(customer_id)
    WHERE me.join_date < s.order_date
    GROUP BY 1, 2, 3, 4
    ORDER BY 1
) AS popular
WHERE row_num = 1;

-- 7. Which item was purchased just before the customer became a member?
SELECT * FROM (
    SELECT
        customer_id,
        product_name,join_date, s.order_date,
        COUNT(product_name) AS num_of_times_product_ordered,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS row_num
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m USING(product_id)
    LEFT JOIN dannys_diner.members me USING(customer_id)
    WHERE me.join_date > s.order_date
    GROUP BY 1,2,3,4
    ORDER BY 1
) AS popular
WHERE row_num = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
    customer_id,
    COUNT(product_id) as num_of_items,
    SUM(m.price) as total_amount
FROM dannys_diner.sales s
JOIN dannys_diner.menu m USING(product_id)
LEFT JOIN dannys_diner.members me USING(customer_id)
WHERE me.join_date > s.order_date
GROUP BY 1
ORDER BY 1;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH multiplier AS (
    SELECT
        s.customer_id,
        m.product_name,
        m.price,
        CASE WHEN product_id = 1 THEN m.price*20 ELSE m.price*10 END AS points
    FROM dannys_diner.menu m
    JOIN dannys_diner.sales s USING(product_id)
)
SELECT
    customer_id,
    SUM(points) AS total_price
FROM multiplier
GROUP BY 1
ORDER BY 2 DESC;

-- 10. In the first week after a customer joins the program (including their
-- join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH earnings AS (
    SELECT
        customer_id,
        s.product_id,
        s.order_date,
        m.join_date
    FROM dannys_diner.sales s
    JOIN dannys_diner.members m USING(customer_id)
    WHERE m.join_date <= s.order_date
)
SELECT
    customer_id,
    SUM(total_point) AS total_point
FROM(
    SELECT
        customer_id,
        product_id,
        SUM(CASE WHEN order_date < join_date + interval '7 DAY' THEN price * 20 ELSE price*10 END) AS total_point
    FROM earnings ea
    JOIN dannys_diner.menu me USING(product_id)
    WHERE extract(MONTH FROM order_date) = 01
    GROUP BY 1,2
) AS stopp
GROUP BY 1;

------------------
-- BONUS QUESTIONS
------------------
-- Join All The Things
-- The members column  with value N stands for NO and Y as YES.
SELECT
    customer_id,
    order_date,
    product_name,
    price,
    CASE WHEN join_date <= order_date THEN 'Y' ELSE 'N' END AS member
FROM dannys_diner.sales s
JOIN dannys_diner.menu m USING(product_id)
LEFT JOIN dannys_diner.members me USING(customer_id)
ORDER BY 1,2;

-- Rank All The Things
WITH users_details AS (
    SELECT *,
        CASE WHEN join_date <= order_date THEN 'Y' ELSE 'N' END AS member
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m USING(product_id)
    LEFT JOIN dannys_diner.members me USING(customer_id)
)
SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member,
    CASE WHEN member = 'Y' THEN (RANK() OVER(PARTITION BY customer_id,member
                       ORDER BY order_date)) ELSE NULL END AS ranking
FROM users_details;
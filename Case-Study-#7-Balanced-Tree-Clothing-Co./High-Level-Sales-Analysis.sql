-- What was the total quantity sold for all products?
SELECT SUM(qty) AS total_quantity
FROM balanced_tree.sales;

-- What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) AS total_revenue
FROM balanced_tree.sales;

-- What was the total discount amount for all products?
SELECT ROUND(SUM(qty * price * discount::numeric)/100,2) AS total_discount
FROM balanced_tree.sales;
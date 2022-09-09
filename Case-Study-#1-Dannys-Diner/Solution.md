1. What is the total amount each customer spent at the restaurant?

```select
distinct s.customer_id,
sum(m.price) as total_amount,
from dannys_diner.sales s
join dannys_diner.menu m using(product_id)
group by 1
```
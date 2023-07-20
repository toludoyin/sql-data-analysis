-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

SELECT
    product_id,
    price,
    ph.level_text||' '||ph1.level_text||'-'||ph2.level_text AS product_name,
    ph1.parent_id AS category_id,
    ph.parent_id AS segment_id,
    ph.id AS style_id,
    ph2.level_text AS category_name,
    ph1.level_text AS segment_name,
    ph.level_text AS style_name
FROM balanced_tree.product_hierarchy ph
JOIN balanced_tree.product_hierarchy ph1 ON ph.parent_id = ph1.id
JOIN balanced_tree.product_hierarchy ph2 ON ph2.id = ph1.parent_id
JOIN balanced_tree.product_prices pp ON pp.id=ph.id;
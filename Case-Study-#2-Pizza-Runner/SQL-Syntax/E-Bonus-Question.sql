/*If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
*/

INSERT INTO pizza_runner.pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (3, 'Supreme');

SELECT * FROM pizza_runner.pizza_names -- query
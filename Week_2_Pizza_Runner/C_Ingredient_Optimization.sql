-- Replacing null and blank values with NULL in both customer_orders and runner_orders
UPDATE pizza_runner.customer_orders
SET exclusions = NULL
WHERE exclusions = 'null'
	OR exclusions = ''

UPDATE pizza_runner.customer_orders
SET extras = NULL
WHERE extras = 'null'
	OR extras = ''

UPDATE pizza_runner.runner_orders
SET distance = NULL
WHERE distance = 'null'

UPDATE pizza_runner.runner_orders
SET duration = NULL
WHERE duration = 'null'

UPDATE pizza_runner.runner_orders
SET cancellation = ''
WHERE cancellation IS NULL

UPDATE pizza_runner.runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null'

-- changing order_time in runner_orders column from varchar to timestamp
ALTER TABLE pizza_runner.runner_orders

ALTER COLUMN pickup_time TYPE TIMESTAMP USING (pickup_time::TIMESTAMP)

-- trimming columns in runner_orders and changing data type
SELECT order_id
	, runner_id
	, pickup_time
	, CAST(CASE 
			WHEN distance LIKE '%km'
				THEN TRIM('km' FROM distance)
			ELSE distance
			END AS DECIMAL) AS distance
	, CAST(CASE 
			WHEN duration LIKE '%mins'
				THEN TRIM('mins' FROM duration)
			WHEN duration LIKE '%minutes'
				THEN TRIM('minutes' FROM duration)
			WHEN duration LIKE '%minute'
				THEN TRIM('minute' FROM duration)
			ELSE duration
			END AS INTEGER) AS duration
	, cancellation
FROM pizza_runner.runner_orders

-- creating temp tables
CREATE TEMP TABLE temp_runnerorders AS (
	SELECT order_id
	, runner_id
	, pickup_time
	, CAST(CASE 
			WHEN distance LIKE '%km'
				THEN TRIM('km' FROM distance)
			ELSE distance
			END AS DECIMAL) AS distance
	, CAST(CASE 
			WHEN duration LIKE '%mins'
				THEN TRIM('mins' FROM duration)
			WHEN duration LIKE '%minutes'
				THEN TRIM('minutes' FROM duration)
			WHEN duration LIKE '%minute'
				THEN TRIM('minute' FROM duration)
			ELSE duration
			END AS INTEGER) AS duration
	, cancellation FROM pizza_runner.runner_orders
	)
-- C.INGREDIENT OPTIMIZATION
--1. What are the standard ingredients for each pizza?
WITH CTE AS (
		SELECT PIZZA_ID
			, CAST(UNNEST(STRING_TO_ARRAY(TOPPINGS, ',')) AS INTEGER) AS TOPPING_ID
		FROM PIZZA_RUNNER.PIZZA_RECIPES
		)

SELECT R.PIZZA_ID
	, T.TOPPING_ID
	, T.TOPPING_NAME
FROM CTE AS R
JOIN PIZZA_RUNNER.PIZZA_TOPPINGS AS T
	ON R.TOPPING_ID = T.TOPPING_ID
ORDER BY PIZZA_ID
	, TOPPING_ID
--2. What was the most commonly added extra?
WITH CTE AS (
		SELECT *
			, CAST(UNNEST(STRING_TO_ARRAY(extras, ',')) AS INTEGER) AS extra
		FROM pizza_runner.customer_orders
		)

SELECT extra
	, topping_name
	, count(extra)
FROM CTE
JOIN pizza_runner.pizza_toppings AS T
	ON CTE.extra = T.topping_id
GROUP BY cte.extra
	, topping_name
ORDER BY count DESC
--3. What was the most common exclusion?
WITH CTE AS (
		SELECT *
			, CAST(UNNEST(STRING_TO_ARRAY(EXCLUSIONS, ',')) AS INTEGER) AS EXCLUSION
		FROM PIZZA_RUNNER.CUSTOMER_ORDERS
		)

SELECT CTE.EXCLUSION
	, TOPPING_NAME
	, COUNT(CTE.EXCLUSION)
FROM CTE
JOIN PIZZA_RUNNER.PIZZA_TOPPINGS AS T
	ON CTE.EXCLUSION = T.TOPPING_ID
GROUP BY CTE.EXCLUSION
	, TOPPING_NAME
ORDER BY COUNT(CTE.EXCLUSION) DESC
/*4. Generate an order item for each record in the customers_orders table in the format of one of the following: 
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/
-- pizza_recipes, pizza_toppings, pizza_names
WITH CTE AS (
		SELECT PIZZA_ID
			, CAST(UNNEST(STRING_TO_ARRAY(TOPPINGS, ',')) AS INTEGER) AS TOPPING_ID
		FROM PIZZA_RUNNER.PIZZA_RECIPES
		)

SELECT R.PIZZA_ID
	, N.pizza_name
	, T.TOPPING_ID
	, T.TOPPING_NAME
	, O.order_id
FROM CTE AS R
JOIN PIZZA_RUNNER.PIZZA_TOPPINGS AS T
	ON R.TOPPING_ID = T.TOPPING_ID
JOIN pizza_runner.pizza_names AS N
	ON R.pizza_id = N.pizza_id
JOIN pizza_runner.customer_orders AS O
	ON N.pizza_id = O.pizza_id
ORDER BY order_id
	, PIZZA_ID
	, TOPPING_ID
--		
WITH CTE_exclusions AS (
		SELECT O.order_id
			, O.pizza_id
			, O.exclusions
			, O.extras
			, N.pizza_name
			, CAST(UNNEST(STRING_TO_ARRAY(EXCLUSIONS, ',')) AS INTEGER) AS excluded_topping
		FROM pizza_runner.customer_orders AS O
		JOIN pizza_runner.pizza_names AS N
			ON O.pizza_id = N.pizza_id
		)
	, CTE_extras AS (
		SELECT *
			, CAST(UNNEST(STRING_TO_ARRAY(extras, ',')) AS INTEGER) AS extra_topping
		FROM pizza_runner.customer_orders
		)

SELECT ext.order_id
	, exc.order_id
	, ext.pizza_id
	, exc.pizza_id
FROM CTE_extras AS ext
FULL JOIN pizza_runner.customer_orders
	ON pizza_runner.customer_orders.order_id = ext.order_id
FULL JOIN CTE_exclusions AS exc
	ON pizza_runner.customer_orders.order_id = exc.order_id
ORDER BY ext.order_id

/*5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/
--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
/*

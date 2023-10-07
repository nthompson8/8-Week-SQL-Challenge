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

/*A. PIZZA METRICS
How many pizzas were ordered?*/
SELECT COUNT(*) AS pizza_order_count
FROM pizza_runner.customer_orders

/*
How many unique customer orders were made?*/
SELECT COUNT(DISTINCT order_id) AS unique_order_count
FROM pizza_runner.customer_orders

/*
How many successful orders were delivered by each runner?*/
SELECT COUNT(cancellation) AS successful_order_count
FROM temp_runnerorders
WHERE cancellation = ''

/* How many of each type of pizza was delivered?*/
SELECT pizza_id
	, COUNT(c.pizza_id) AS number_delivered
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
GROUP BY pizza_id

/*
How many Vegetarian and Meatlovers were ordered by each customer?*/
SELECT c.customer_id
	, p.pizza_name
	, COUNT(p.pizza_name) AS number_ordered
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
JOIN pizza_runner.pizza_names AS p
	ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id
	, p.pizza_name
ORDER BY c.customer_id
/*What was the maximum number of pizzas delivered in a single order?*/
WITH CTE_pizzas_delivered AS (
		SELECT c.order_id
			, COUNT(c.customer_id) AS number_ordered
		FROM pizza_runner.customer_orders AS c
		JOIN temp_runnerorders AS t
			ON c.order_id = t.order_id
		WHERE cancellation = ''
		GROUP BY c.order_id
			, customer_id
		)	
SELECT MAX(number_ordered)
FROM CTE_pizzas_delivered

/*For each customer, how many delivered pizzas had at least 1 change and how many had no changes?*/
-- AT LEAST 1 CHANGE
SELECT COUNT(*) AS order_count_changes
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
	AND (exclusions IS NOT NULL
		OR extras IS NOT NULL)

-- NO CHANGES
SELECT COUNT(*) AS order_count_no_changes
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
	AND (exclusions IS NULL
		AND extras IS NULL)

/*How many pizzas were delivered that had both exclusions and extras?*/
SELECT COUNT(*) AS pizza_count
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
	AND (exclusions IS NOT NULL
		AND extras IS NOT NULL)

/*What was the total volume of pizzas ordered for each hour of the day?*/
SELECT EXTRACT(HOUR FROM order_time) AS hour_of_day
	, COUNT(pizza_id)
FROM pizza_runner.customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day

/*What was the volume of orders for each day of the week?*/
SELECT COUNT(*)
	, TO_CHAR(order_time, 'Day') AS day
FROM pizza_runner.customer_orders
GROUP BY day
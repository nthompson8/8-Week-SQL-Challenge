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
-- B. RUNNER AND CUSTOMER EXPERIENCE
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)*/
SELECT runner_id
	, COUNT(CASE 
			WHEN pickup_time BETWEEN '2020-01-01'
					AND '2020-01-07'
				THEN 1
			ELSE NULL
			END) AS orders_in_week1
	, COUNT(CASE 
			WHEN pickup_time BETWEEN '2020-01-08'
					AND '2020-01-14'
				THEN 1
			ELSE NULL
			END) AS orders_in_week2
	, COUNT(CASE 
			WHEN pickup_time BETWEEN '2020-01-15'
					AND '2020-01-21'
				THEN 1
			ELSE NULL
			END) AS orders_in_week3
FROM temp_runnerorders
GROUP BY runner_id;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_id
	, AVG(duration) AS avg_travel_time
FROM temp_runnerorders
GROUP BY runner_id
ORDER BY runner_id
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH CTE_time AS (
		SELECT count(c.order_id) AS number_of_pizzas
			, c.order_id
			, t.duration
		FROM temp_runnerorders AS t
		JOIN pizza_runner.customer_orders AS c
			ON t.order_id = c.order_id
		GROUP BY c.order_id
			, t.duration
		)

SELECT number_of_pizzas
	, ROUND(avg(duration), 0) AS avg_prep_mins
FROM CTE_time
GROUP BY number_of_pizzas
ORDER BY number_of_pizzas
-- It seems there could be a positive relationship, however the lowest average prep time was with pizzas with 2 orders
-- 4. What was the average distance travelled for each customer?
WITH CTE_distance AS (
		SELECT c.customer_id AS customer_id
			, t.distance AS distance
		FROM temp_runnerorders AS t
		JOIN pizza_runner.customer_orders AS c
			ON t.order_id = c.order_id
		GROUP BY c.customer_id
			, t.distance
		ORDER BY c.customer_id
		)

SELECT customer_id
	, ROUND(avg(distance), 0) AS avg_distance
FROM CTE_distance
GROUP BY customer_id
ORDER BY customer_id
-- 5. What was the difference between the longest and shortest delivery times for all orders?
WITH CTE AS (
		SELECT count(c.order_id) AS number_of_pizzas
			, c.order_id
			, t.duration
		FROM temp_runnerorders AS t
		JOIN pizza_runner.customer_orders AS c
			ON t.order_id = c.order_id
		GROUP BY c.order_id
			, t.duration
		)

SELECT MAX(DURATION)
	, MIN(DURATION)
	, (MAX(DURATION) - MIN(DURATION)) AS difference
FROM CTE

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- Runner 2 is the fastest, twice as fast as runner 3.
SELECT runner_id
	, AVG(duration) AS avg_speed
FROM temp_runnerorders AS t
JOIN pizza_runner.customer_orders AS c
	ON t.order_id = c.order_id
GROUP BY runner_id
ORDER BY runner_id

SELECT runner_id
	, order_id
	, ROUND(AVG(distance / duration * 60), 1) AS avg_speed
FROM temp_runnerorders
WHERE cancellation = ''
GROUP BY runner_id
	, order_id
-- 7. What is the successful delivery percentage for each runner?
WITH CTE_success AS (
		SELECT *
			, CASE 
				WHEN cancellation = ''
					THEN 'Success'
				ELSE 'Unsuccessful'
				END AS success
		FROM temp_runnerorders
		)

SELECT runner_id
	, count(distance) AS successful_deliveries
	, count(order_id) AS number_of_orders
	, ROUND(100 * (CAST(COUNT(distance) AS DECIMAL) / COUNT(order_id)), 2) AS PERCENT
FROM CTE_success
GROUP BY runner_id
ORDER BY runner_id

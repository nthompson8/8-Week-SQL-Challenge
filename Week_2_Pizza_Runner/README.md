### Available Data
#### Table 1: runners
The runners table shows the registration_date for each new runner.

| runner_id | registration_date |
|---------- |------------------- |
| 1          | 2021-01-01                 |
| 2          | 2021-01-03                 |
| 3          | 2021-01-08                 |
| 4          | 2021-01-15                 |

#### Table 2: customer_orders
Customer pizza orders are captured in the customer_orders table with 1 row for each individual pizza that is part of the order.

The pizza_id relates to the type of pizza which was ordered while the exclusions are the ingredient_id values which should be removed from the pizza and the extras are the ingredient_id values which need to be added to the pizza.

Note that customers can order multiple pizzas in a single order with varying exclusions and extras values even if the pizza is the same type!

The exclusions and extras columns will need to be cleaned up before using them in your queries.

| order_id | customer_id | pizza_id | exclusions | extras | order_time           |
|---------- |-------------- |------------- |------------- |--------- |--------------------- |
| 1          | 101                | 1               |                  |             | 2021-01-01 18:05:02 |
| 2          | 101                | 1               |                  |             | 2021-01-01 19:00:52 |
| 3          | 102                | 1               |                  |             | 2021-01-02 23:51:23 |
| 3          | 102                | 2               | NaN         |             | 2021-01-02 23:51:23 |
| 4          | 103                | 1               | 4               |             | 2021-01-04 13:23:46 |
| 4          | 103                | 1               | 4               |             | 2021-01-04 13:23:46 |
| 4          | 103                | 2               | 4               |             | 2021-01-04 13:23:46 |
| 5          | 104                | 1               | null           | 1          | 2021-01-08 21:00:29 |
| 6          | 101                | 2               | null           | null       | 2021-01-08 21:03:13 |
| 7          | 105                | 2               | null           | 1          | 2021-01-08 21:20:29 |
| 8          | 102                | 1               | null           | null       | 2021-01-09 23:54:33 |
| 9          | 103                | 1               | 4               | 1, 5     | 2021-01-10 11:22:59 |
| 10        | 104                | 1               | null           | null       | 2021-01-11 18:34:49 |
| 10        | 104                | 1               | 2, 6           | 1, 4     | 2021-01-11 18:34:49 |

#### Table 3: runner_orders
After each order is received through the system, they are assigned to a runner; however, not all orders are fully completed and can be canceled by the restaurant or the customer.

The pickup_time is the timestamp at which the runner arrives at the Pizza Runner headquarters to pick up the freshly cooked pizzas. The distance and duration fields are related to how far and how long the runner had to travel to deliver the order to the respective customer.

There are some known data issues with this table, so be careful when using this in your queries - make sure to check the data types for each column in the schema SQL!

| order_id | runner_id | pickup_time         | distance | duration | cancellation           |
|---------- |------------ |---------------------- |---------- |----------- |-------------------------- |
| 1          | 1               | 2021-01-01 18:15:34 | 20km      | 32 minutes  |                             |
| 2          | 1               | 2021-01-01 19:10:54 | 20km      | 27 minutes  |                             |
| 3          | 1               | 2021-01-03 00:12:37 | 13.4km  | 20 mins       | NaN                     |
| 4          | 2               | 2021-01-04 13:53:03 | 23.4      | 40               | NaN                     |
| 5          | 3               | 2021-01-08 21:10:57 | 10          | 15               | NaN                     |
| 6          | 3               | null                          | null        | null            | Restaurant Cancellation |
| 7          | 2               | 2020-01-08 21:30:45 | 25km    | 25mins       | null                     |
| 8          | 2               | 2020-01-10 00:15:02 | 23.4 km | 15 minute  | null                     |
| 9          | 2               | null                          | null        | null            | Customer Cancellation  |
| 10        | 1               | 2020-01-11 18:50:20 | 10km    | 10 minutes | null                     |

#### Table 4: pizza_names
At the moment, Pizza Runner only has 2 pizzas available: Meat Lovers or Vegetarian!

| pizza_id | pizza_name  |
|---------- |------------------ |
| 1          | Meat Lovers   |
| 2          | Vegetarian      |

#### Table 5: pizza_recipes
Each pizza_id has a standard set of toppings which are used as part of the pizza recipe.

| pizza_id | toppings                                 |
|---------- |--------------------------------- |
| 1          | 1, 2, 3, 4, 5, 6, 8, 10              |
| 2          | 4, 6, 7, 9, 11, 12                    |

#### Table 6: pizza_toppings
This table contains all of the topping_name values with their corresponding topping_id value.

| topping_id | topping_name   |
|------------ |------------------ |
| 1                | Bacon               |
| 2                | BBQ Sauce        |
| 3                | Beef                  |
| 4                | Cheese              |
| 5                | Chicken             |
| 6                | Mushrooms      |
| 7                | Onions               |
| 8                | Pepperoni         |
| 9                | Peppers            |
| 10              | Salami                |
| 11              | Tomatoes          |
| 12              | Tomato Sauce   |

---
### Data Cleaning
* Replacing null and blank values with NULL in both customer_orders and runner_orders
````sql
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
````
* Changing order_time in runner_orders column from character varying to timestamp
````sql
ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP USING (pickup_time::TIMESTAMP)
````
* Trimming columns in runner_orders and changing data type
````sql
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
````
* Creating temp tables based on steps taken above
````sql
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
````
---
#### A. Pizza Metrics

**1. How many pizzas were ordered?**
```sql
SELECT COUNT(*) AS pizza_order_count
FROM pizza_runner.customer_orders
```
14 pizzas were ordered.

**2. How many unique customer orders were made?**
```sql
SELECT COUNT(*) AS pizza_order_count
FROM pizza_runner.customer_orders
```
There were 10 unique customer orders.

**3. How many successful orders were delivered by each runner?**
```sql
How many successful orders were delivered by each runner?*/
SELECT runner_id
	, COUNT(cancellation) AS successful_order_count
FROM temp_runnerorders
WHERE cancellation = ''
GROUP BY runner_id
```
| runner_id | successful_order_count |
|-----------|------------------------|
| 1         | 4                      |
| 2         | 3                      |
| 3         | 1                      |

**4. How many of each type of pizza was delivered?**
```sql
SELECT pizza_id
	, COUNT(c.pizza_id) AS number_delivered
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
GROUP BY pizza_id
```

| pizza_id | number_delivered |
|----------|------------------|
| 1        | 9                |
| 2        | 3                |

**5. How many Vegetarian and Meatlovers were ordered by each customer?**

```sql
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
```

| customer_id | pizza_name    | number_ordered |
|-------------|---------------|-----------------|
| 101         | Meatlovers    | 2               |
| 101         | Vegetarian    | 1               |
| 102         | Meatlovers    | 2               |
| 102         | Vegetarian    | 1               |
| 103         | Meatlovers    | 3               |
| 103         | Vegetarian    | 1               |
| 104         | Meatlovers    | 3               |
| 105         | Vegetarian    | 1               |

**6. What was the maximum number of pizzas delivered in a single order?**
```sql
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
```
The maximum number of pizzas delivered in a single order is 3. 

**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**

**At least one change:**
```sql
SELECT COUNT(*) AS order_count_changes
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
	AND (
		exclusions IS NOT NULL
		OR extras IS NOT NULL
		)
```
|Order Count Changes|
|--|
|6|

**No changes**
```sql
SELECT COUNT(*) AS order_count_no_changes
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
	AND (
		exclusions IS NULL
		AND extras IS NULL
		)
```
|Order Count No Changes|
|-|
|6|

**8. How many pizzas were delivered that had both exclusions and extras?**
```sql
SELECT COUNT(*) AS pizza_count
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
	AND (
		exclusions IS NOT NULL
		AND extras IS NOT NULL
		)
```
Only 1 pizza that was delivered had both exclusions and extras.

**9. What was the total volume of pizzas ordered for each hour of the day?**
```sql
SELECT COUNT(*) AS pizza_count
FROM pizza_runner.customer_orders AS c
JOIN temp_runnerorders AS t
	ON c.order_id = t.order_id
WHERE cancellation = ''
	AND (
		exclusions IS NOT NULL
		AND extras IS NOT NULL
		)
```
| hour_of_day | count |
|-------------|-------|
| 11          | 1     |
| 13          | 3     |
| 18          | 3     |
| 19          | 1     |
| 21          | 3     |
| 23          | 3     |

**10. What was the volume of orders for each day of the week?**
```sql
SELECT COUNT(*)
	, TO_CHAR(order_time, 'Day') AS day
FROM pizza_runner.customer_orders
GROUP BY day
```
| count | day        |
|-------|------------|
| 5     | Saturday   |
| 3     | Thursday   |
| 1     | Friday     |
| 5     | Wednesday  |

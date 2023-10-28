## Introduction
Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:
sales
menu
members

### Case Study Questions

Each of the following case study questions can be answered using a single SQL statement:

### 1. What is the total amount each customer spent at the restaurant?
````sql
SELECT sales.customer_id
	, SUM(menu.price) AS total_spend
FROM dannys_diner.sales AS sales
JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;
````
| Customer ID   | Total Spend |
|---|---|
| A | 76  |
| B | 74  |
| C | 36  |

### 2. How many days has each customer visited the restaurant?

````sql
SELECT COUNT(DISTINCT sales.order_date) AS number_of_visits
	, sales.customer_id
FROM dannys_diner.sales AS sales
GROUP BY sales.customer_id;
````
| Number of Visits | Customer ID |
|-------------------|-------------|
| 4                 | A       |
| 6                 | B         |
| 2                 | C        |

### 3. What was the first item from the menu purchased by each customer?

````sql
WITH CTE
AS (
	SELECT customer_id
		, order_date
		, product_name
		, RANK() OVER (
			PARTITION BY customer_id ORDER BY order_date
			) AS rank
		, ROW_NUMBER() OVER (
			PARTITION BY customer_id ORDER BY order_date
			) AS row
	FROM dannys_diner.sales AS sales
	JOIN dannys_diner.menu AS menu
		ON sales.product_id = menu.product_id
	)
SELECT customer_id
	, product_name
FROM CTE
WHERE rank = 1;
````
| Customer ID | Product Name |
|------------ |-------------- |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |
| C           | ramen        |

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
SELECT menu.product_name
	, COUNT(*) AS total_purchases
FROM dannys_diner.sales AS sales
JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_purchases DESC LIMIT 1;
````
|Product Name|Total Purchases|
|------|-----|
|Ramen|8|
### 5. Which item was the most popular for each customer?

````sql
SELECT COUNT(*) AS orders
	, menu.product_name
	, sales.customer_id
	, DENSE_RANK() OVER (
		PARTITION BY sales.customer_id ORDER BY COUNT(*) DESC
		) AS rank
FROM dannys_diner.sales AS sales
JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
	, menu.product_name
ORDER BY orders DESC
	, sales.customer_id;
````
| Orders | Product Name | Customer ID | Rank |
|-------- |-------------- |------------ |----- |
| 3      | ramen     | A        | 1    |
| 3      | ramen      | C       | 1    |
| 2      | curry      | A       | 2    |
| 2      | sushi      | B       | 1    |
| 2      | curry      | B       | 1    |
| 2      | ramen      | B       | 1    |
| 1      | sushi      | A       | 3    |

### 6. Which item was purchased first by the customer after they became a member?

````sql
WITH CTE
AS (
	SELECT s.customer_id
		, s.order_date
		, menu.product_name
		, mem.join_date
		, RANK() OVER (
			PARTITION BY s.customer_id ORDER BY s.order_date
			) AS rank
	FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.members AS mem
		ON s.customer_id = mem.customer_id
	INNER JOIN dannys_diner.menu AS menu
		ON s.product_id = menu.product_id
	WHERE s.order_date >= mem.join_date
	)
SELECT *
FROM CTE
WHERE rank = 1;
````
| Customer ID | Order Date  | Product Name | Join Date   | Rank |
|------------ |------------ |-------------- |------------ |----- |
| A           | 2021-01-07  | curry      | 2021-01-07  | 1    |
| B           | 2021-01-11  | sushi      | 2021-01-09  | 1    |

### 7. Which item was purchased just before the customer became a member?

````sql
WITH CTE
AS (
	SELECT S.customer_id
		, order_date
		, menu.product_name
		, join_date
		, RANK() OVER (
			PARTITION BY S.customer_id ORDER BY order_date
			) AS rank
	FROM dannys_diner.members AS mem
	INNER JOIN dannys_diner.sales AS S
		ON mem.customer_id = S.customer_id
	INNER JOIN dannys_diner.menu AS menu
		ON S.product_id = menu.product_id
	WHERE order_date < join_date
	)
SELECT *
FROM CTE
WHERE rank = 1;
````
| Customer ID | Order Date  | Product Name | Join Date   | Rank |
|------------ |------------ |-------------- |------------ |----- |
| A           | 2021-01-01  | sushi      | 2021-01-07  | 1    |
| A           | 2021-01-01  | curry     | 2021-01-07  | 1    |
| B           | 2021-01-01  | curry     | 2021-01-09  | 1    |

### 8. What is the total items and amount spent for each member before they became a member?

````sql
SELECT S.customer_id
	, COUNT(menu.product_name) AS total_items
	, SUM(menu.price) AS amount_spent
FROM dannys_diner.members AS mem
INNER JOIN dannys_diner.sales AS s
	ON mem.customer_id = s.customer_id
INNER JOIN dannys_diner.menu AS menu
	ON s.product_id = menu.product_id
WHERE order_date < join_date
GROUP BY s.customer_id;
````
| Customer ID | Total Items | Amount Spent |
|------------ |------------ |------------- |
| B           | 3           | 40          |
| A           | 2           | 25          |

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

````sql
SELECT sales.customer_id
	, SUM(CASE 
			WHEN product_name = 'sushi'
				THEN price * 10 * 2
			ELSE price * 10
			END) AS points
FROM dannys_diner.menu AS menu
INNER JOIN dannys_diner.sales AS sales
	ON menu.product_id = sales.product_id
GROUP BY customer_id;
````
| Customer ID | Points |
|------------ |------- |
| B           | 940    |
| C           | 360    |
| A           | 860    |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
First, I will create a "Point Information Table"
````sql
CREATE VIEW point_info
AS
SELECT *
	, (
		CASE 
			WHEN product_name = 'sushi'
				THEN price * 10 * 2
			ELSE price * 10
			END
		) AS points
FROM dannys_diner.menu AS menu
INNER JOIN dannys_diner.sales AS sales
	ON menu.product_id = sales.product_id;
````
| Product | Points |
| ------- | ------ |
| sushi   | 200    |
| curry   | 150    |
| ramen   | 120    |

````sql
WITH promo_period
AS (
	SELECT customer_id
		, order_date
		, order_date - join_date AS date_diff
		, points
		, CASE 
			WHEN product_name IN (
					'curry'
					, 'ramen'
					, 'sushi'
					)
				AND order_date - join_date BETWEEN 0
					AND 6
				THEN points * 2
			WHEN product_name IN (
					'curry'
					, 'ramen'
					)
				AND order_date - join_date > 6
				THEN points
			WHEN product_name = 'sushi'
				AND order_date - join_date > 6
				THEN points * 2
			ELSE 0
			END AS adj_point
	FROM point_info
	WHERE order_date - join_date > 0
	)
SELECT customer_id
	, SUM(adj_point) AS total_points
FROM promo_period
GROUP BY customer_id;
````
### Bonus question: Join all the things
````sql
SELECT sales.customer_id
	, sales.order_date
	, menu.product_name
	, menu.price
	, CASE 
		WHEN order_date >= join_date
			THEN 'Y'
		ELSE 'N'
		END AS member
FROM dannys_diner.sales AS sales
LEFT JOIN dannys_diner.members AS members
	ON sales.customer_id = members.customer_id
INNER JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
ORDER BY sales.customer_id
	, sales.order_date
	, menu.product_name;
````
| Customer ID | Order Date | Product Name | Price | Member |
|------------ |------------ |-------------- |------ |------- |
| A           | 2021-01-01  | curry        | 15    | N      |
| A           | 2021-01-01  | sushi        | 10    | N      |
| A           | 2021-01-07  | curry        | 15    | Y      |
| A           | 2021-01-10  | ramen        | 12    | Y      |
| A           | 2021-01-11  | ramen        | 12    | Y      |
| A           | 2021-01-11  | ramen        | 12    | Y      |
| B           | 2021-01-01  | curry        | 15    | N      |
| B           | 2021-01-02  | curry        | 15    | N      |
| B           | 2021-01-04  | sushi        | 10    | N      |
| B           | 2021-01-11  | sushi        | 10    | Y      |
| B           | 2021-01-16  | ramen        | 12    | Y      |
| B           | 2021-02-01  | ramen        | 12    | Y      |
| C           | 2021-01-01  | ramen        | 12    | N      |
| C           | 2021-01-01  | ramen        | 12    | N      |
| C           | 2021-01-07  | ramen        | 12    | N      |

### Bonus Question: Rank all the things

````sql
WITH CTE
AS (
	SELECT sales.customer_id
		, sales.order_date
		, menu.product_name
		, menu.price
		, CASE 
			WHEN order_date >= join_date
				THEN 'Y'
			ELSE 'N'
			END AS member
		, RANK() OVER (
			PARTITION BY sales.customer_id ORDER BY CASE 
					WHEN order_date >= join_date
						THEN 'Y'
					ELSE 'N'
					END
				, order_date
			) AS ranking
	FROM dannys_diner.sales AS sales
	LEFT JOIN dannys_diner.members AS members
		ON sales.customer_id = members.customer_id
	INNER JOIN dannys_diner.menu AS menu
		ON sales.product_id = menu.product_id
	ORDER BY sales.customer_id
		, sales.order_date
		, menu.product_name
		, ranking
	)
SELECT customer_id
	, order_date
	, product_name
	, price
	, member
	, ranking
FROM CTE
ORDER BY customer_id
	, order_date
	, product_name
	, ranking;
````

| Customer ID | Order Date | Product Name | Price | Member | Ranking |
|------------ |------------ |-------------- |------ |------- |------- |
| A           | 2021-01-01  | curry        | 15    | N      | 1       |
| A           | 2021-01-01  | sushi        | 10    | N      | 1       |
| A           | 2021-01-07  | curry        | 15    | Y      | 3       |
| A           | 2021-01-10  | ramen        | 12    | Y      | 4       |
| A           | 2021-01-11  | ramen        | 12    | Y      | 5       |
| A           | 2021-01-11  | ramen        | 12    | Y      | 5       |
| B           | 2021-01-01  | curry        | 15    | N      | 1       |
| B           | 2021-01-02  | curry        | 15    | N      | 2       |
| B           | 2021-01-04  | sushi        | 10    | N      | 3       |
| B           | 2021-01-11  | sushi        | 10    | Y      | 4       |
| B           | 2021-01-16  | ramen        | 12    | Y      | 5       |
| B           | 2021-02-01  | ramen        | 12    | Y      | 6       |
| C           | 2021-01-01  | ramen        | 12    | N      | 1       |
| C           | 2021-01-01  | ramen        | 12    | N      | 1       |
| C           | 2021-01-07  | ramen        | 12    | N      | 3       |

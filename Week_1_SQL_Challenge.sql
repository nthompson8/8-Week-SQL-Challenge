-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id
	, SUM(menu.price) AS total_spend
FROM dannys_diner.sales AS sales
JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT COUNT(DISTINCT sales.order_date) AS number_of_visits
	, sales.customer_id
FROM dannys_diner.sales AS sales
GROUP BY sales.customer_id;

-- 3. What was the first item from the menu purchased by each customer?
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

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu.product_name
	, COUNT(*) AS total_purchases
FROM dannys_diner.sales AS sales
JOIN dannys_diner.menu AS menu
	ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_purchases DESC LIMIT 1;

-- 5. Which item was the most popular for each customer?
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

-- 6. Which item was purchased first by the customer after they became a member?
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

-- 7. Which item was purchased just before the customer became a member?
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

-- 8. What is the total items and amount spent for each member before they became a member?
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

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
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

-- Point Information Table
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

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- create point_info view, add case statements for points
-- add where clause to make sure only dates after the join date are included
-- put query as CTE, make following query with sum of points grouped by customer id
WITH promo_period
AS (
	SELECT customer_id
		, order_date
		, order_date - join_date AS date_diff
		, points
		, CASE 
			WHEN product_name IN ('curry', 'ramen', 'sushi')
				AND order_date - join_date BETWEEN 0
					AND 6
				THEN points * 2
			WHEN product_name IN ('curry', 'ramen')
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

-- Bonus question: join all the things
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

-- Bonus question: rank all the things
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

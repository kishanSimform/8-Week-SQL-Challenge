--------------------------
-- Case Study Questions --
--------------------------

USE [Week 1 - Danny's Diner];

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(price) AS [Total Amount]
FROM sales s 
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id;
GO

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS [Visit]
FROM sales
GROUP BY customer_id;
GO

-- 3. What was the first item from the menu purchased by each customer?
WITH cte AS (
	SELECT customer_id, m.product_name,
		DENSE_RANK() OVER(PARTITION BY customer_id 
			ORDER BY order_date) AS [First Item]
	FROM sales s 
	JOIN menu m
		ON s.product_id = m.product_id 
	)
SELECT DISTINCT customer_id, product_name
FROM cte
WHERE [First Item] = 1;
GO

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte AS (
	SELECT TOP 1 
		s.product_id, m.product_name
	FROM sales s
	JOIN menu m
		ON s.product_id = m.product_id
	GROUP BY s.product_id, m.product_name
	ORDER BY COUNT(customer_id) DESC
	)
SELECT s.customer_id, c.product_name, 
	COUNT(*) AS [Total Purchased]
FROM sales s
JOIN cte c
	ON s.product_id = c.product_id
GROUP BY s.customer_id, c.product_name;
GO

-- 5. Which item was the most popular for each customer?
WITH cte AS (
	SELECT customer_id, product_id, 
		RANK() OVER (PARTITION BY customer_id 
			ORDER BY COUNT(product_id) DESC) [Popular]
	FROM sales
	GROUP BY customer_id, product_id
	)
SELECT customer_id, m.product_name
FROM cte c
JOIN menu m
	ON c.product_id = m.product_id
WHERE Popular = 1;
GO


-- 6. Which item was purchased first by the customer after they became a member?
WITH cte AS (
	SELECT customer_id, m.product_name, s.order_date, 
		RANK() OVER (PARTITION BY customer_id
			ORDER BY order_date) AS [Row]
	FROM sales s 
	JOIN menu m
		ON s.product_id = m.product_id
	WHERE order_date >= 
		(SELECT join_date FROM members m 
		WHERE s.customer_id = m.customer_id)
	)
SELECT customer_id, product_name, order_date 
FROM cte
WHERE Row = 1;
GO

-- 7. Which item was purchased just before the customer became a member?
WITH cte AS (
	SELECT customer_id, m.product_name, s.order_date, 
		RANK() OVER (PARTITION BY customer_id
			ORDER BY order_date desc) AS [Row]
	FROM sales s 
	JOIN menu m
		ON s.product_id = m.product_id
	WHERE order_date <
		(SELECT join_date 
		FROM members m 
		WHERE s.customer_id = m.customer_id)
	)
SELECT customer_id, product_name, order_date 
FROM cte
WHERE Row = 1;
GO

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT customer_id, 
	COUNT(s.product_id) [Total Items], 
	SUM(price) [Total Amount]
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
WHERE order_date < 
		(SELECT join_date 
		FROM members m 
		WHERE s.customer_id = m.customer_id)
GROUP BY customer_id;
GO

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?
SELECT customer_id, 
	SUM(CASE 
			WHEN m.product_name = 'sushi' 
				THEN m.price * 20
			ELSE m.price * 10 
		END) AS [Points]
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
GROUP BY customer_id;
GO

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
-- how many points do customer A and B have at the end of January?
SELECT s.customer_id, 
	SUM(CASE 
			WHEN m.product_name = 'sushi' 
				THEN price * 20
			WHEN order_date BETWEEN join_date AND DATEADD(DAY, 6, join_date)
				THEN price * 20
			ELSE price * 10
	END) AS [Total Points]
FROM sales s
JOIN members ms
	ON s.customer_id= ms.customer_id
JOIN menu m
	ON s.product_id = m.product_id
WHERE s.order_date < '2021-01-31'
GROUP BY s.customer_id;
GO


---------------------
-- Bonus Questions --
---------------------

-- Join All The Things
SELECT s.customer_id, order_date, m.product_name, m.price,
	CASE 
		WHEN order_date >= join_date AND s.customer_id = ms.customer_id
			THEN 'Y'
		ELSE 'N'
	END AS [member]
FROM sales s
JOIN menu m
	ON s.product_id = m.product_id
LEFT JOIN members ms
	ON s.customer_id = ms.customer_id
ORDER BY 1, 2, 3;
GO

-- Rank All The Things
WITH cte AS (
	SELECT s.customer_id, order_date, m.product_name, m.price,
		CASE 
			WHEN order_date >= join_date AND s.customer_id = ms.customer_id
				THEN 'Y'
			ELSE 'N'
		END AS [member]
	FROM sales s
	JOIN menu m
		ON s.product_id = m.product_id
	LEFT JOIN members ms
		ON s.customer_id = ms.customer_id
	)
SELECT customer_id, order_date, product_name, price, member,
	CASE member
		WHEN 'Y'
			THEN RANK() OVER(PARTITION BY customer_id, (CASE WHEN member = 'Y' THEN 1 END)
				ORDER BY order_date)
		ELSE NULL
	END AS [ranking]
FROM cte
ORDER BY 1, 2, 3;
GO

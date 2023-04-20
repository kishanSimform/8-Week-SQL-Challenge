----------------------
-- Product Analysis --
----------------------

USE [Week 7 - Balanced Tree Clothing Co.];

-- 1. What are the top 3 products by total revenue before discount?
WITH cte AS (	
	SELECT product_name, 
		SUM(qty * p.price) [revenue],
		DENSE_RANK() OVER (ORDER BY SUM(qty * p.price) DESC) [rank]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	GROUP BY product_name
	)
SELECT product_name, revenue
FROM cte 
WHERE rank <= 3;
GO

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT segment_name, 
	SUM(qty) [total_quantity],
	SUM(qty * p.price) [total_revenue],
	SUM(qty * p.price * CAST(discount / 100.0 AS decimal(10,2))) [total_discount]
FROM sales s
JOIN product_details p
	ON s.prod_id = p.product_id
GROUP BY segment_name;
GO

-- 3. What is the top selling product for each segment?
WITH cte AS (	
	SELECT product_name, segment_name, 
		SUM(qty) [total_sell],
		DENSE_RANK() OVER (PARTITION BY segment_name ORDER BY SUM(qty) DESC) [rank]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	GROUP BY product_name, segment_name
	)
SELECT product_name, segment_name, total_sell
FROM cte
WHERE RANK = 1;
GO

-- 4. What is the total quantity, revenue and discount for each category?
SELECT category_name, 
	SUM(qty) [total_quantity],
	SUM(qty * p.price) [total_revenue],
	SUM(qty * p.price * CAST(discount / 100.0 AS decimal(10,2))) [total_discount]
FROM sales s
JOIN product_details p
	ON s.prod_id = p.product_id
GROUP BY category_name;
GO

-- 5. What is the top selling product for each category?
WITH cte AS (	
	SELECT product_name, category_name, 
		SUM(qty) [total_sell],
		DENSE_RANK() OVER (PARTITION BY category_name ORDER BY SUM(qty) DESC) [rank]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	GROUP BY product_name, category_name
	)
SELECT product_name, category_name, total_sell
FROM cte
WHERE RANK = 1;
GO

-- 6. What is the percentage split of revenue by product for each segment?

WITH cte AS (
	SELECT product_name, segment_name,
		SUM(qty * p.price) [revenue]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	GROUP BY product_name, segment_name
	)
SELECT product_name, segment_name, revenue, 
	CAST(ROUND(revenue * 100.0 / (SUM(revenue) OVER(PARTITION BY segment_name)), 2) AS decimal(10,2)) [revenue_percentage_by_segment]
FROM cte;
GO

-- 7. What is the percentage split of revenue by segment for each category?
WITH cte AS (
	SELECT segment_name, category_name,
		SUM(qty * p.price) [revenue]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	GROUP BY segment_name, category_name
	)
SELECT segment_name, category_name, revenue, 
	CAST(ROUND(revenue * 100.0 / (SUM(revenue) OVER(PARTITION BY category_name)), 2) AS decimal(10,2)) [revenue_percentage_by_category]
FROM cte;
GO

-- 8. What is the percentage split of total revenue by category?
SELECT category_name,
		CAST(ROUND(SUM(qty * p.price) * 100.0 / (SELECT SUM(qty * price) FROM sales), 2) AS DECIMAL(10,2)) [revenue]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
GROUP BY category_name;
GO

-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
SELECT product_name,
      CAST(ROUND(COUNT(product_name) * 100.0 / (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) AS DECIMAL(10,2)) AS [product_penetration]
FROM sales s
JOIN product_details p
	ON s.prod_id = p.product_id
GROUP BY product_name
ORDER BY product_penetration DESC;
GO

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH cte AS (
	SELECT s.prod_id, txn_id, product_name
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	),
cte2 AS (
	SELECT
		c1.product_name [product_1],
		c2.product_name [product_2], 
		c3.product_name [product_3], 
		COUNT(c1.txn_id) [txn_count],
		DENSE_RANK() OVER (ORDER BY COUNT(c1.txn_id) DESC) [rank]
	FROM cte c1
	JOIN cte c2
		ON c1.txn_id = c2.txn_id and c1.prod_id < c2.prod_id
	JOIN cte c3
		ON c2.txn_id = c3.txn_id and c2.prod_id < c3.prod_id
	GROUP BY c1.product_name, c2.product_name, c3.product_name
	)
SELECT product_1, product_2, product_3, txn_count
FROM cte2
WHERE rank = 1;
GO
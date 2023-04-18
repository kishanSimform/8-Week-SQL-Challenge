--------------------------------
-- 3. Product Funnel Analysis --
--------------------------------

USE [Week 6 - Clique Bait];

/*
Using a single SQL query - create a new output table which has the following details:
- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?
*/

DROP TABLE IF EXISTS #product_detail;

WITH cte AS (
	SELECT page_name [product],
		SUM(CASE
			WHEN event_name = 'Page View' THEN 1
			ELSE 0
		END) AS [views],
		SUM(CASE
			WHEN event_name = 'Add to Cart' THEN 1
			ELSE 0
		END) AS [added_cart]
	FROM events e
	JOIN event_identifier ei
		ON e.event_type = ei.event_type
	JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	WHERE product_category IS NOT NULL
	GROUP BY page_name
	),
cte2 AS (	
	SELECT page_name [product],
		COUNT(visit_id) [purchased]
	FROM events e
	JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	JOIN event_identifier ei
		ON e.event_type = ei.event_type
	WHERE visit_id IN (
		SELECT visit_id
		FROM events e
		JOIN event_identifier ei
			ON e.event_type = ei.event_type
		WHERE event_name = 'Purchase'
		)
		AND event_name = 'Add to Cart'
	GROUP BY page_name
	)
SELECT cte.product, views, added_cart, added_cart - purchased AS [abandoned_cart], purchased
INTO #product_detail
FROM cte
JOIN cte2
	ON cte.product = cte2.product;
GO

SELECT *
FROM #product_detail;
GO


-- Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

DROP TABLE IF EXISTS #product_category_detail;

SELECT product_category, 
	SUM(views) [views], 
	SUM(added_cart) [added_cart], 
	SUM(abandoned_cart) [abandoned_cart], 
	SUM(purchased) [purchased]
INTO #product_category_detail
FROM #product_detail pd
JOIN page_hierarchy ph
	ON pd.product = ph.page_name
GROUP BY product_category;
GO

SELECT *
FROM #product_category_detail;
GO


-- Use your 2 new output tables - answer the following questions:

-- 1. Which product had the most views, cart adds and purchases?
SELECT 'most_view' [most], product, views [numbers]
	FROM #product_detail
	WHERE views = (SELECT MAX(views) FROM #product_detail)
UNION
SELECT 'most_cart_add', product, added_cart
	FROM #product_detail
	WHERE added_cart = (SELECT MAX(added_cart) FROM #product_detail)
UNION
SELECT 'most_purchase', product, views
	FROM #product_detail
	WHERE purchased = (SELECT MAX(purchased) FROM #product_detail);
GO

-- 2. Which product was most likely to be abandoned?
WITH cte AS (	
	SELECT product, abandoned_cart,
		RANK() OVER (ORDER BY abandoned_cart DESC) [rank]
	FROM #product_detail
	)
SELECT product [most_abandoner_product], abandoned_cart [number_abandoned_cart]
FROM cte
WHERE RANK = 1;
GO

-- 3. Which product had the highest view to purchase percentage?
WITH cte AS (	
	SELECT product, 
		CAST(ROUND(purchased * 100.0 / views, 2) AS DECIMAL(10,2)) [view_to_purchase_percentage],
		RANK() OVER (ORDER BY purchased * 100.0 / views DESC) [rank]
	FROM #product_detail
	)
SELECT product, view_to_purchase_percentage
FROM cte
WHERE rank = 1;
GO

-- 4. What is the average conversion rate from view to cart add?
WITH cte AS (
	SELECT *, CAST(ROUND(added_cart * 100.0 / views, 2) AS DECIMAL(10,2)) [view_to_cart_percentage]
	FROM #product_detail
	)
SELECT CAST(AVG(view_to_cart_percentage) AS DECIMAL(10,2)) [avg_view_to_cart_conversion]
FROM cte;
GO

-- 5. What is the average conversion rate from cart add to purchase?
SELECT CAST(ROUND(SUM(purchased) * 100.0 / SUM(added_cart), 2) AS DECIMAL(10,2)) [avg_cart_to_purchase_conversion]
FROM #product_detail;
GO

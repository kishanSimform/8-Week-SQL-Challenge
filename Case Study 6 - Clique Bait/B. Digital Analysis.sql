-------------------------
-- 2. Digital Analysis --
-------------------------

USE [Week 6 - Clique Bait];

-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) [user_count]
FROM users;
GO

-- 2. How many cookies does each user have on average?
WITH cte AS (	
	SELECT user_id, COUNT(cookie_id) [cookie]
	FROM users
	GROUP BY user_id
	)
SELECT AVG(cookie) [avg_cookie]
FROM cte;
GO

-- 3. What is the unique number of visits by all users per month?
SELECT DATEPART(MONTH, event_time) [month],
	COUNT(DISTINCT visit_id) [count]
FROM users
JOIN events
	ON users.cookie_id = events.cookie_id
GROUP BY DATEPART(MONTH, event_time)
ORDER BY month;
GO

-- 4. What is the number of events for each event type?
SELECT event_name, COUNT(visit_id) [count]
FROM events e
JOIN event_identifier ei
	ON e.event_type = ei.event_type
GROUP BY event_name;
GO

-- 5. What is the percentage of visits which have a purchase event?
SELECT event_name, 
	CAST(ROUND(COUNT(DISTINCT visit_id) * 100.0 / (SELECT COUNT(DISTINCT visit_id) FROM events),2) AS NUMERIC(10,2)) AS [purchase_percentage]
FROM events e
JOIN event_identifier ei
	ON e.event_type = ei.event_type
WHERE event_name = 'Purchase'
GROUP BY event_name;
GO

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

SELECT 
	COUNT(DISTINCT visit_id) [number_of_visit], 
	CAST(ROUND(COUNT(DISTINCT visit_id) *100.0 / (SELECT COUNT(DISTINCT visit_id) FROM events WHERE page_id = 12),2) AS NUMERIC(10,2)) AS [purchase_from_checkout_percentage],
	CAST(ROUND(COUNT(DISTINCT visit_id) *100.0 / (SELECT COUNT(DISTINCT visit_id) FROM events),2) AS NUMERIC(10,2)) AS [purchase_percentage]
FROM events e
JOIN page_hierarchy ph
	ON e.page_id = ph.page_id
WHERE page_name = 'Checkout' 
	AND visit_id NOT IN (
		SELECT DISTINCT visit_id
		FROM events e
		JOIN event_identifier ei
			ON e.event_type = ei.event_type
		WHERE event_name = 'Purchase'
	);
GO


-- 7. What are the top 3 pages by number of views?
WITH cte AS (	
	SELECT page_name, COUNT(visit_id) [views],
		RANK() OVER (ORDER BY COUNT(visit_id) DESC) [rank]
	FROM events e
	JOIN page_hierarchy ph
		ON e.page_id = ph.page_id
	JOIN event_identifier ei
		ON e.event_type = ei.event_type
	WHERE event_name = 'Page View'
	GROUP BY page_name
	)
SELECT page_name, views
FROM cte 
WHERE rank <= 3
ORDER BY views DESC;
GO

-- 8. What is the number of views and cart adds for each product category?
SELECT product_category,
	SUM(CASE
		WHEN event_name = 'Page View'
			THEN 1
		ELSE 0
	END) AS [page_view],
	SUM(CASE
		WHEN event_name = 'Add to Cart'
			THEN 1
		ELSE 0
	END) AS [add_to_cart]
FROM events e
JOIN page_hierarchy ph
	ON e.page_id = ph.page_id
JOIN event_identifier ei
	ON e.event_type = ei.event_type
WHERE product_id IS NOT NULL
GROUP BY product_category;
GO

-- 9. What are the top 3 products by purchases?
WITH cte AS (	
	SELECT page_name,
		COUNT(visit_id) [count],
		RANK() OVER (ORDER BY COUNT(event_name) DESC) [rank]
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
		AND product_id IS NOT NULL
		AND event_name = 'Add to Cart'
	GROUP BY page_name
	)
SELECT *
FROM cte
WHERE rank <= 3;
GO

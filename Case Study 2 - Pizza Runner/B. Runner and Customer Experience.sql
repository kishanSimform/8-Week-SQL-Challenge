------------------------------------
-- Runner and Customer Experience --
------------------------------------

USE [Week 2 - Pizza Runner];

-- Cleaning and Transformation data of customer_orders table

DROP TABLE IF EXISTS #customer_orders;

SELECT order_id, customer_id, pizza_id, order_time,
	CASE  
		WHEN exclusions NOT LIKE '[0-9]%' THEN NULL
		ELSE exclusions
	END AS [exclusions],
	CASE  
		WHEN extras NOT LIKE '[0-9]%' THEN NULL
		ELSE extras
	END AS [extras]
INTO #customer_orders
FROM customer_orders;
GO

SELECT * FROM #customer_orders;
GO

-- Cleaning and Transformation data of runner_orders table

DROP TABLE IF EXISTS #runner_orders;

SELECT order_id, runner_id, 
	CASE  
		WHEN ISDATE(pickup_time) <> 1 
			THEN NULL
		ELSE pickup_time
	END AS [pickup_time],
	CASE
		WHEN distance LIKE '%km' 
			THEN TRIM('km' FROM distance)
		WHEN distance NOT LIKE '[0-9]%'
			THEN NULL
		ELSE distance
	END AS [distance],
	CASE 
		WHEN duration LIKE '%min%' 
			THEN TRIM('minutes' FROM duration)
		WHEN duration NOT LIKE '[0-9]%' 
			THEN NULL
		ELSE duration
	END AS [duration],
	CASE 
		WHEN cancellation NOT LIKE '%Cancel%' 
			THEN NULL
		ELSE cancellation
	END cancellation
INTO #runner_orders
FROM runner_orders;
GO

SELECT * FROM #runner_orders;
GO

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT DATEPART(WEEK, registration_date) [Week], 
	COUNT(runner_id) [Runners]
FROM runners
GROUP BY DATEPART(WEEK, registration_date);
GO

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH cte AS (
	SELECT runner_id, 
		DATEDIFF(MINUTE, order_time, pickup_time) [Pickup Time]
	FROM #customer_orders c
	JOIN #runner_orders r
		ON c.order_id = r.order_id
	)
SELECT runner_id, AVG([Pickup Time]) [Average]
FROM cte
GROUP BY runner_id;
GO

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH cte AS (
	SELECT c.order_id, customer_id, 
		COUNT(pizza_id) [Pizza Count],
		DATEDIFF(MINUTE, order_time, pickup_time) [Prepare Time]
	FROM #customer_orders c
	JOIN #runner_orders r
		ON c.order_id = r.order_id
	WHERE cancellation IS NULL
	GROUP BY c.order_id, customer_id, order_time, pickup_time
	)
SELECT [Pizza Count], 
	AVG([Prepare Time]) [Average PrepareTime]
FROM cte
GROUP BY [Pizza Count];
GO

-- 4. What was the average distance travelled for each customer?
SELECT customer_id, 
	AVG(CAST(distance AS DECIMAL)) [Average Distance]
FROM #customer_orders c
JOIN #runner_orders r
	ON c.order_id = r.order_id
WHERE distance IS NOT NULL
GROUP BY customer_id;
GO

-- 5. What was the difference between the longest and shortest delivery times for all orders?
WITH cte AS (
	SELECT order_id, 
		AVG(CAST(duration AS DECIMAL)) [Avearge Time]
	FROM #runner_orders
	WHERE duration IS NOT NULL
	GROUP BY order_id
	)
SELECT MAX(CAST([Avearge Time] AS INT)) - MIN(CAST([Avearge Time] AS INT)) [Difference]
FROM cte;
GO

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, c.order_id, 
	COUNT(pizza_id) [Pizza Count],
	CAST(distance AS DECIMAL(5,2)) / CAST(duration AS DECIMAL(5,2)) * 60 AS [Speed (KM/H)]
FROM #customer_orders c
JOIN #runner_orders r
	ON c.order_id = r.order_id
WHERE distance IS NOT NULL
GROUP BY runner_id, c.order_id, distance, duration;
GO

-- 7. What is the successful delivery percentage for each runner?
WITH cte AS (
	SELECT runner_id, COUNT(order_id) [Total Order],
		SUM(
			CASE 
			WHEN cancellation IS NULL 
				THEN 1
			ELSE 0
			END) AS [Succeed]
	FROM #runner_orders
	GROUP BY runner_id
	)
SELECT runner_id, 
	CAST(CAST([Succeed] AS INT) * 100 / CAST([Total Order] AS INT) AS VARCHAR) + '%' AS [Succeed Percentage]
FROM cte;
GO

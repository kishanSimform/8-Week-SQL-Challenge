----------------------
-- A. Pizza Metrics --
----------------------

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

SELECT * FROM #customer_orders;
SELECT * FROM #runner_orders;
GO


-- 1. How many pizzas were ordered?
SELECT COUNT(order_id) [Pizza Ordered]
FROM customer_orders;
GO

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) [Unique Customer Orders]
FROM customer_orders;
GO

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) [Successful Orders]
FROM #runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
GO

-- 4. How many of each type of pizza was delivered?
SELECT CAST(p.pizza_name AS VARCHAR) [Pizza Name], 
	COUNT(c.order_id) [Delivered]
FROM #customer_orders c
JOIN #runner_orders r
	ON c.order_id = r.order_id
JOIN pizza_names p
	ON p.pizza_id = c.pizza_id
WHERE r.cancellation IS NULL
GROUP BY CAST(p.pizza_name AS VARCHAR);
GO

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT * FROM
	(
		SELECT customer_id, order_id, 
			CAST(pizza_name AS VARCHAR(MAX)) [pizza_name]
		FROM customer_orders c
		JOIN pizza_names p
			ON c.pizza_id = p.pizza_id
	) t
	PIVOT (
		COUNT(order_id)
		FOR pizza_name IN (
			[Meatlovers],
			[Vegetarian])
	) AS tab;	
GO

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH cte AS (
	SELECT c.order_id, COUNT(pizza_id) [Total Pizza]
	FROM #customer_orders c
	JOIN #runner_orders r
		ON c.order_id = r.order_id
	WHERE r.cancellation IS NULL
	GROUP BY c.order_id
	)
SELECT MAX([Total Pizza]) AS [Maximum Pizza]
FROM cte;
GO

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id,
	SUM(
	CASE
		WHEN exclusions LIKE '[0-9]%' OR extras LIKE '[0-9]%'
			THEN 1
		ELSE 0
		END
	) AS [atleast_one_change],
	SUM(
	CASE 
		WHEN exclusions IS NULL AND extras IS NULL 
			THEN 1
		ELSE 0
		END 
	) AS [no_change]
FROM #customer_orders c
JOIN #runner_orders r
	ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
GROUP BY customer_id;
GO

-- 8. How many pizzas were delivered that had both exclusions and extras?     
SELECT COUNT(pizza_id) [Pizza Count]
FROM #customer_orders c
JOIN #runner_orders r
	ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
	AND exclusions IS NOT NULL
	AND extras IS NOT NULL;
GO

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATEPART(DAY, order_time) [Day],
	DATEPART(HOUR, order_time) [Hour],
	COUNT(pizza_id) [Pizza Count]
FROM customer_orders
GROUP BY DATEPART(HOUR, order_time), 
	DATEPART(DAY, order_time)
ORDER BY Day;
GO

-- 10. What was the volume of orders for each day of the week?
SELECT DATEPART(WEEK, order_time) [Week], 
	DATEPART(WEEKDAY, order_time) [Day Of Week], 
	COUNT(pizza_id) [Pizza Count]
FROM customer_orders
GROUP BY DATEPART(WEEK, order_time), 
	DATEPART(WEEKDAY, order_time)
ORDER BY Week;
GO

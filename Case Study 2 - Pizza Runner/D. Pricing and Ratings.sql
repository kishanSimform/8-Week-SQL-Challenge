----------------------------
-- D. Pricing and Ratings --
----------------------------

USE [Week 2 - Pizza Runner]

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

ALTER TABLE #customer_orders 
ADD record INT IDENTITY(1,1)

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

DROP TABLE IF EXISTS #extras;

WITH cte AS (
	SELECT record, order_id, pizza_id, TRIM(value) [extras] 
	FROM #customer_orders
	CROSS APPLY STRING_SPLIT(CAST(extras AS VARCHAR), ',')
	)
SELECT record, order_id, pizza_id, topping_id, STRING_AGG(CAST(topping_name AS VARCHAR), ', ') [extras] 
INTO #extras
FROM cte c
JOIN pizza_toppings pt
	ON c.extras = pt.topping_id
GROUP BY record, order_id, pizza_id, topping_id

SELECT * FROM #extras;


-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH cte AS (
	SELECT pizza_id,
		SUM(
			CASE pizza_id
				WHEN 1 THEN 12
				ELSE 10
			END) AS [Prize]
	FROM #runner_orders r
	JOIN #customer_orders c
		ON r.order_id = c.order_id
	WHERE cancellation IS NULL
	GROUP BY pizza_id
	)
SELECT SUM(Prize) [Total Amount]
FROM cte;
GO


-- 2. What if there was an additional $1 charge for any pizza extras?
-- - Add cheese is $1 extra
WITH cte AS (
	SELECT pizza_id,
		SUM(
			CASE pizza_id
				WHEN 1 THEN 12 
				ELSE 10
			END) AS [Prize]
	FROM #runner_orders r
	JOIN #customer_orders c
		ON r.order_id = c.order_id
	WHERE cancellation IS NULL
	GROUP BY pizza_id
	)
SELECT SUM(Prize) + (SELECT COUNT(*) FROM #extras) [Total Amount]
FROM cte;
GO


-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
-- how would you design an additional table for this new dataset - 
-- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS runner_rating;

CREATE TABLE runner_rating (
	runner_id INT,
	customer_id INT,
	order_id INT,
	rating INT
	);
GO

INSERT INTO runner_rating
SELECT *, ABS(CHECKSUM(NEWID()))%5 + 1
FROM (
	SELECT DISTINCT runner_id, customer_id, c.order_id
	FROM #customer_orders c 
	JOIN #runner_orders r
	ON c.order_id = r.order_id
	WHERE r.cancellation IS NULL ) t;
GO

SELECT * FROM runner_rating;
GO

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- - customer_id
-- - order_id
-- - runner_id
-- - rating
-- - order_time
-- - pickup_time
-- - Time between order and pickup
-- - Delivery duration
-- - Average speed
-- - Total number of pizzas

SELECT 
	rr.customer_id, 
	rr.order_id, 
	rr.runner_id, 
	rr.rating, 
	c.order_time, 
	r.pickup_time, 
	DATEDIFF(MINUTE, order_time, pickup_time) [prepare_time], 
	r.duration, 
	CAST(distance AS DECIMAL(5,2))/CAST(duration AS DECIMAL(5,2)) * 60 AS [avg_speed],
	COUNT(*) [total_pizza]
FROM runner_rating rr
JOIN #customer_orders c
	ON rr.order_id = c.order_id
JOIN #runner_orders r
	ON c.order_id = r.order_id
GROUP BY rr.customer_id, 
	rr.order_id, 
	rr.runner_id, 
	rr.rating, 
	c.order_time, 
	r.pickup_time, 
	DATEDIFF(MINUTE, order_time, pickup_time), 
	r.duration, 
	CAST(distance AS DECIMAL(5,2))/CAST(duration AS DECIMAL(5,2)) * 60;
GO

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - 
-- how much money does Pizza Runner have left over after these deliveries?
WITH cte AS (
	SELECT c.order_id,
		CASE
			WHEN CAST(p.pizza_name AS VARCHAR) = 'MeatLovers' THEN 12 - 0.30 * CAST(distance AS DECIMAL(5,2))
			ELSE 10 - 0.30 * CAST(distance AS DECIMAL(5,2))
		END AS [Price]
	FROM #runner_orders r
	JOIN #customer_orders c
		ON r.order_id = c.order_id
	JOIN pizza_names p	
		ON p.pizza_id = c.pizza_id
	WHERE cancellation IS NULL
	)
SELECT SUM(Price) [left_price] FROM cte;
GO

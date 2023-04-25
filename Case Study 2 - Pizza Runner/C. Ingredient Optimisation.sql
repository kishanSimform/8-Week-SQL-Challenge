-----------------------------
-- Ingredient Optimisation --
-----------------------------

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
ADD record INT IDENTITY(1,1);
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

-- Create table for Exclusions toppings of pizza

DROP TABLE IF EXISTS #exclusions;

WITH cte AS (
	SELECT record, order_id, pizza_id, TRIM(value) [exclusions] 
	FROM #customer_orders
	CROSS APPLY STRING_SPLIT(CAST(exclusions AS VARCHAR), ',')
	)
SELECT record, order_id, pizza_id, topping_id, STRING_AGG(CAST(topping_name AS VARCHAR), ', ') [exclusions]
INTO #exclusions
FROM cte c
JOIN pizza_toppings pt
	ON c.exclusions = pt.topping_id
GROUP BY record, order_id, pizza_id, topping_id;
GO

SELECT * FROM #exclusions;
GO

-- Create table for Extras toppings of pizza

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
GROUP BY record, order_id, pizza_id, topping_id;
GO

SELECT * FROM #extras;
GO


-- 1. What are the standard ingredients for each pizza?
WITH cte AS (
	SELECT pizza_id, TRIM(value) [toppings] 
	FROM pizza_recipes pr
	CROSS APPLY STRING_SPLIT(CAST(toppings AS VARCHAR), ',')
	),
cte2 AS (
	SELECT pizza_id, topping_name 
	FROM cte c
	JOIN pizza_toppings pt
		ON c.toppings = pt.topping_id
	)
SELECT CAST(pizza_name AS VARCHAR) [Pizza Name], 
	STRING_AGG(CAST(topping_name AS VARCHAR), ', ') [Standard Ingredients] 
FROM cte2 c
JOIN pizza_names p
	ON c.pizza_id = p.pizza_id
GROUP BY CAST(pizza_name AS VARCHAR);
GO


-- 2. What was the most commonly added extra?
WITH cte AS (
	SELECT TRIM(value) [extra]
	FROM #customer_orders
	CROSS APPLY STRING_SPLIT(CAST(extras AS VARCHAR), ',')
	WHERE extras IS NOT NULL
	),
cte2 AS (
	SELECT extra, COUNT(*) [Count]
	FROM cte
	GROUP BY extra
	)
SELECT topping_name, Count 
FROM cte2 c
JOIN pizza_toppings t
ON c.extra = t.topping_id
WHERE Count = (
	SELECT MAX(Count) FROM cte2 );
GO


-- 3. What was the most common exclusion?
WITH cte AS (
	SELECT TRIM(value) [exclusion]
	FROM #customer_orders
	CROSS APPLY STRING_SPLIT(CAST(exclusions AS VARCHAR), ',')
	WHERE exclusions IS NOT NULL
	),
cte2 AS (
	SELECT exclusion, COUNT(*) [Count]
	FROM cte
	GROUP BY exclusion
	)
SELECT topping_name, Count 
FROM cte2 c
JOIN pizza_toppings t
	ON c.exclusion = t.topping_id
WHERE Count = (
	SELECT MAX(Count) FROM cte2 );
GO


-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- - Meat Lovers
-- - Meat Lovers - Exclude Beef
-- - Meat Lovers - Extra Bacon
-- - Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH cte AS (
	SELECT record, order_id, 
		CAST(p.pizza_name AS VARCHAR) [pizza_name]
	FROM #customer_orders c
	JOIN pizza_names p
		ON c.pizza_id = p.pizza_id
	WHERE exclusions IS NULL AND extras IS NULL
	),
cte_exclusion AS (
	SELECT record, order_id, 
		CAST(p.pizza_name AS VARCHAR) [pizza_name], 
		'Exclude ' + STRING_AGG(exclusions, ', ') [exclusions]
	FROM #exclusions e
	JOIN pizza_names p
		ON e.pizza_id = p.pizza_id
	GROUP BY record, order_id, CAST(p.pizza_name AS VARCHAR)
	),
cte_extras AS (
	SELECT record, order_id, 
		CAST(p.pizza_name AS VARCHAR) [pizza_name], 
		'Extra ' + STRING_AGG(extras, ', ') [extras]
	FROM #extras e
	JOIN pizza_names p
		ON e.pizza_id = p.pizza_id
	GROUP BY record, order_id, CAST(p.pizza_name AS VARCHAR)
	),
cte_union AS (
	SELECT * 
		FROM cte_exclusion
	UNION ALL
	SELECT * 
		FROM cte_extras
	)
SELECT order_id,
	pizza_name + ' - ' + STRING_AGG(exclusions, ' - ') [Pizza]
	FROM cte_union
	GROUP BY record, order_id, pizza_name
UNION ALL
SELECT order_id, pizza_name [Pizza] 
	FROM cte
	ORDER BY order_id;
GO


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- - For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH cte AS (
	SELECT * FROM
	(SELECT record, c.order_id, c.pizza_id, toppings
	FROM #customer_orders c
	JOIN #runner_orders r
		ON c.order_id = r.order_id
	JOIN (
		SELECT pizza_id, TRIM(value) [toppings] 
				FROM pizza_recipes pr
				CROSS APPLY STRING_SPLIT(CAST(toppings AS VARCHAR), ',')
		) t
		ON c.pizza_id = t.pizza_id
	WHERE r.cancellation IS NULL
	EXCEPT
	SELECT record, e.order_id, pizza_id, topping_id
		FROM #exclusions e
		JOIN #runner_orders r
			ON e.order_id = r.order_id
		WHERE r.cancellation IS NULL ) A
	UNION ALL
	SELECT record, e.order_id, pizza_id, topping_id
		FROM #extras e
		JOIN #runner_orders r
			ON e.order_id = r.order_id
		WHERE r.cancellation IS NULL 
	),
cte2 AS (
	SELECT record, order_id, c.pizza_id, CAST(pizza_name AS VARCHAR) [pizza_name], toppings, COUNT(*) [Count], CAST(topping_name AS VARCHAR) [Topping]
	FROM cte c
	JOIN pizza_names pn
		ON c.pizza_id = pn.pizza_id
	JOIN pizza_toppings pt
		ON CAST(c.toppings AS INT) = pt.topping_id
	GROUP BY record, order_id, c.pizza_id, CAST(pizza_name AS VARCHAR), toppings, CAST(topping_name AS VARCHAR)
	),
cte3 AS (
	SELECT *,
		CASE
			WHEN Count = 2 THEN '2x' + Topping
			ELSE Topping
		END AS [full_pizza]
	FROM cte2
	)
SELECT order_id, pizza_name + ': ' + STRING_AGG(full_pizza, ', ') 
FROM cte3
GROUP BY record, order_id, pizza_id, pizza_name;
GO


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH cte AS (
	SELECT pizza_id, TRIM(value) [toppings] 
	FROM pizza_recipes pr
	CROSS APPLY STRING_SPLIT(CAST(toppings AS VARCHAR), ',')
	),
cte2 AS (
	SELECT pizza_id, topping_name,
		CASE
			WHEN pizza_id = 1 
			THEN (SELECT COUNT(*)
				FROM #customer_orders c
				JOIN #runner_orders r
					ON c.order_id = r.order_id
				WHERE pizza_id = 1 AND
					r.cancellation IS NULL
				GROUP BY pizza_id)
			ELSE (SELECT COUNT(*)
				FROM #customer_orders c
				JOIN #runner_orders r
					ON c.order_id = r.order_id
				WHERE pizza_id = 2 AND
					r.cancellation IS NULL
				GROUP BY pizza_id)
			END AS [Count]
	FROM cte c
	JOIN pizza_toppings pt
		ON c.toppings = pt.topping_id
	),
cte3 AS (
	SELECT CAST(topping_name AS VARCHAR) [topping], SUM(Count) [Count]
	FROM cte2 c
	GROUP BY CAST(topping_name AS VARCHAR)
	)
SELECT topping,
	cte3.Count - COALESCE(exc.Count, 0) + COALESCE(ext.Count, 0) [Total Count]
FROM cte3
LEFT JOIN (
	SELECT exclusions, COUNT(*) [Count]
	FROM #exclusions e
	JOIN #runner_orders r
		ON e.order_id = r.order_id
	WHERE r.cancellation IS NULL
	GROUP BY exclusions 
	) exc
	ON cte3.topping = exc.exclusions
LEFT JOIN (
	SELECT extras, COUNT(*) [Count]
	FROM #extras e
	JOIN #runner_orders r
		ON e.order_id = r.order_id
	WHERE r.cancellation IS NULL
	GROUP BY extras 
	) ext
	ON cte3.topping = ext.extras
ORDER BY [Total Count] DESC;
GO

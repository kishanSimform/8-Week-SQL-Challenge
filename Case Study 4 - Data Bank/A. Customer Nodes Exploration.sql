-----------------------------------
-- A. Customer Nodes Exploration --
-----------------------------------

USE [Week 4 - Data Bank];

-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) [unique_nodes]
FROM customer_nodes;
GO

-- 2. What is the number of nodes per region?
SELECT region_name, COUNT(DISTINCT node_id) [node_count]
FROM customer_nodes c
JOIN regions r
	ON c.region_id = r.region_id
GROUP BY region_name;
GO

-- 3. How many customers are allocated to each region?
SELECT region_name, COUNT(DISTINCT customer_id) [customer_count]
FROM customer_nodes c
JOIN regions r
	ON c.region_id = r.region_id
GROUP BY region_name;
GO

-- 4. How many days on average are customers reallocated to a different node?
WITH cte AS (
	SELECT customer_id, node_id,
		DATEDIFF(DAY, start_date, end_date) [diff]
	FROM customer_nodes
	WHERE end_date <> '12-31-9999'
	GROUP BY customer_id, node_id, start_date, end_date
	),
cte2 AS (
	SELECT customer_id, node_id, 
		SUM(diff) [sum]
	FROM cte
	GROUP BY customer_id, node_id
	)
SELECT AVG(sum) [avg_day]
FROM cte2;
GO

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH cte AS (
	SELECT region_id,
		DATEDIFF(DAY, start_date, end_date) [diff]
	FROM customer_nodes
	WHERE end_date <> '12-31-9999'
	GROUP BY region_id, start_date, end_date
	)
SELECT DISTINCT region_id, 
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY diff) OVER (PARTITION BY region_id) [median],
	PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY diff) OVER (PARTITION BY region_id) [80th_percentile],
	PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY diff) OVER (PARTITION BY region_id) [95th_percentile]
FROM cte;
GO

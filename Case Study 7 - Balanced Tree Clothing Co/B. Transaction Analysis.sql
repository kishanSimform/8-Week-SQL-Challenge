--------------------------
-- Transaction Analysis --
--------------------------

USE [Week 7 - Balanced Tree Clothing Co.];

-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) [unique_transaction]
FROM sales;
GO

-- 2. What is the average unique products purchased in each transaction?
SELECT COUNT(prod_id) / COUNT(DISTINCT txn_id) [avg_unique_product]
FROM sales;
GO

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH cte AS (	
	SELECT txn_id, SUM(qty * price * (1 - CAST(discount / 100.0 AS decimal(10,2)))) [revenue]
	FROM sales
	GROUP BY txn_id
	)
SELECT TOP 1
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) OVER() [25th_percentile],
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue) OVER() [50th_percentile],
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) OVER() [75th_percentile]
FROM cte;
GO

-- 4. What is the average discount value per transaction?
SELECT AVG(discount_price) [avg_discount_price]
FROM (
	SELECT txn_id, SUM(qty * price * CAST(discount / 100.0 AS decimal(10,2))) [discount_price]
	FROM sales s
	GROUP BY txn_id
	) t;
GO

-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT 
	CASE member
		WHEN 't' THEN 'true'
		ELSE 'false'
	END AS member, 
	CAST(COUNT(DISTINCT txn_id) * 100.0 / (SELECT COUNT(DISTINCT txn_id) FROM sales) AS DECIMAL(10,2)) 
	AS [percentage]
FROM sales
GROUP BY member;
GO

-- 6. What is the average revenue for member transactions and non-member transactions?
SELECT 
	CASE member
		WHEN 't' THEN 'true'
		ELSE 'false'
	END AS member, 
	CAST(AVG(total_revenue) AS decimal(10,2)) [avg_revenue]
FROM (
	SELECT member, SUM(qty * price * (1 - CAST(discount / 100.0 AS decimal(10,2)))) [total_revenue]
	FROM sales
	GROUP BY txn_id, member
	) t
GROUP BY member;
GO

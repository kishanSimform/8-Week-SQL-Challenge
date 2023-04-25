------------------------------
-- B. Customer Transactions --
------------------------------

USE [Week 4 - Data Bank];

-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(*) [count], SUM(txn_amount) [total_amount]
FROM customer_transactions
GROUP BY txn_type;
GO

-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH cte AS (
	SELECT customer_id, COUNT(*) [count], AVG(txn_amount) [avg_amount]
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id, txn_type
	)
SELECT AVG(count) [avg_deposit], AVG(avg_amount) [avg_amount]
FROM cte;
GO

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH cte AS (
	SELECT customer_id, DATEPART(MONTH, txn_date) [month],
		SUM(CASE 
			WHEN txn_type = 'deposit' THEN 1 
			ELSE 0
		END) AS [deposit_count],
		SUM(CASE 
			WHEN txn_type = 'purchase' THEN 1 
			ELSE 0 
		END) AS [purchase_count],
		SUM(CASE 
			WHEN txn_type = 'withdrawal' THEN 1 
			ELSE 0 
		END) AS [withdrawal_count]
	FROM customer_transactions
	GROUP BY customer_id, DATEPART(MONTH, txn_date)
	)
SELECT month, COUNT(customer_id) [customer_count]
FROM cte 
WHERE deposit_count > 1 AND
	(purchase_count = 1 OR withdrawal_count = 1)
GROUP BY month;
GO

-- 4. What is the closing balance for each customer at the end of the month?
DROP TABLE IF EXISTS #databank;

WITH cte AS (
    SELECT DISTINCT customer_id, DATEPART(MONTH, txn_date) [month],
        SUM(CASE 
            WHEN txn_type = 'deposit' 
                THEN txn_amount
            ELSE -txn_amount
        END) AS amount
    FROM customer_transactions
    GROUP BY customer_id, DATEPART(MONTH, txn_date)
    ),
cte2 AS (
    SELECT customer_id, month,
        SUM(amount) OVER(PARTITION BY customer_id ORDER BY month) [total_amount]
    FROM cte
       )
SELECT * 
INTO #databank
FROM cte2;
GO

WITH cte3 AS (
    SELECT DISTINCT customer_id, 
        DATEPART(MONTH, DATEADD(MONTH, value, (SELECT MIN(txn_date) FROM customer_transactions))) [month_part]
    FROM customer_transactions
    JOIN GENERATE_SERIES(0, 12, 1)
        ON DATEADD(MONTH, value, (SELECT MIN(txn_date) FROM customer_transactions)) 
			< (SELECT MAX(txn_date) FROM customer_transactions)
    )
MERGE INTO #databank t USING cte3 s
    ON (t.customer_id = s.customer_id) AND (t.month = s.month_part)
WHEN NOT MATCHED BY TARGET
    THEN INSERT (customer_id, month, total_amount)
    VALUES (s.customer_id, s.month_part, NULL);
GO

SELECT customer_id, month,
	CASE 
		WHEN total_amount IS NULL 
			THEN LAST_VALUE(total_amount) IGNORE NULLS 
				OVER (PARTITION BY customer_id ORDER BY month)
		ELSE total_amount
	END AS [closing_balance]
FROM #databank
ORDER BY customer_id, month;
GO

/* Closing Amount in Pivot Table */

SELECT *
FROM (
	SELECT customer_id, month,
		CASE
		WHEN total_amount IS NULL
			THEN LAST_VALUE(total_amount) IGNORE NULLS
				OVER (PARTITION BY customer_id ORDER BY month)
		ELSE total_amount
		END AS [closing_balance]
	FROM #databank
	) t
PIVOT (
	MAX(closing_balance)
	FOR month IN ([1],[2],[3],[4])
	) piv
ORDER BY customer_id;
GO

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?

WITH cte AS (
	SELECT customer_id, month,
		CASE 
			WHEN total_amount IS NULL 
				THEN LAST_VALUE(total_amount) IGNORE NULLS 
					OVER (PARTITION BY customer_id ORDER BY month)
			ELSE total_amount
		END AS [closing_balance]
	FROM #databank
	),
cte2 AS (
	SELECT customer_id, month, closing_balance,
		LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month) [growth]
	FROM cte
	),
cte3 AS (
	SELECT customer_id, month, closing_balance,
		CASE
			WHEN growth > 0 THEN (growth + growth * 0.05)
			WHEN growth < 0 THEN (growth - growth * 0.05)
			ELSE 0
		END AS diff,
		CASE
			WHEN growth > 0 AND (closing_balance > (growth + growth * 0.05)) THEN 1
			WHEN growth < 0 AND (closing_balance > (growth - growth * 0.05)) THEN 1
			ELSE 0
		END AS perc
	FROM cte2
	),
cte4 AS (
	SELECT customer_id, SUM(perc) [sum]
	FROM cte3
	GROUP BY customer_id
	HAVING SUM(perc) > 0
	)
SELECT CAST(COUNT(customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM customer_nodes) AS DECIMAL(10,2)) [percentage]
FROM cte4;
GO

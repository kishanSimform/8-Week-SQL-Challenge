----------------------------------
-- C. Data Allocation Challenge --
----------------------------------

/*
To test out a few different hypotheses - 
the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time

For this multi-part challenge question - 
you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer

Using all of the data available - how much data would have been required for each option on a monthly basis?
*/

USE [Week 4 - Data Bank];

-- running customer balance column that includes the impact each transaction

SELECT customer_id, txn_date, txn_amount, txn_type,
	SUM(CASE
		WHEN txn_type = 'deposit'
			THEN txn_amount
		ELSE -txn_amount
	END) OVER (PARTITION BY customer_id ORDER BY txn_date) AS [running_balance]
FROM customer_transactions
ORDER BY customer_id;
GO


-- customer balance at the end of each month

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


-- minimum, average and maximum values of the running balance for each customer

WITH cte AS (
	SELECT customer_id, txn_date, txn_amount, txn_type,
		SUM(CASE
			WHEN txn_type = 'deposit'
				THEN txn_amount
			ELSE -txn_amount
		END) OVER (PARTITION BY customer_id ORDER BY txn_date) AS [running_balance]
	FROM customer_transactions
	)
SELECT *,
	MIN(running_balance) OVER(PARTITION BY customer_id ORDER BY txn_date) [min_running_balance],
	MAX(running_balance) OVER(PARTITION BY customer_id ORDER BY txn_date) [max_running_balance],
	AVG(running_balance) OVER(PARTITION BY customer_id ORDER BY txn_date) [avg_running_balance]
FROM cte;
GO

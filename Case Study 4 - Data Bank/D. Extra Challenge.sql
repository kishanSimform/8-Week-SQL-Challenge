------------------------
-- D. Extra Challenge --
------------------------

/*
Data Bank wants to try another option which is a bit more difficult to implement - 
they want to calculate data growth using an interest calculation, 
just like in a traditional savings account you might have with a bank.

If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers 
by increasing their data allocation based off the interest calculated on a daily basis at the end of each day,
how much data would be required for this option on a monthly basis?

Special notes:

Data Bank wants an initial calculation which does not allow for compounding interest, 
however they may also be interested in a daily compounding interest calculation 
so you can try to perform this calculation if you have the stamina!
*/

USE [Week 4 - Data Bank];

WITH cte AS (
	SELECT customer_id, txn_date, txn_amount, txn_type,
		COALESCE(LEAD(txn_date) OVER (PARTITION BY customer_id ORDER BY txn_date), '04-30-2020') [next_txn],
		SUM(CASE
			WHEN txn_type = 'deposit'
				THEN txn_amount
			ELSE -txn_amount
		END) OVER (PARTITION BY customer_id ORDER BY txn_date) AS [running_balance]
	FROM customer_transactions
	),
cte2 AS (
	SELECT *,
		running_balance * (0.06/365) * DATEDIFF(DAY, txn_date, next_txn) [interest]
	FROM cte
	)
SELECT DATEPART(MONTH, txn_date) [month], SUM(interest) [required_data]
FROM cte2
GROUP BY DATEPART(MONTH, txn_date)
ORDER BY Month;
GO

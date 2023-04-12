-----------------------------------
-- C. Challenge Payment Question --
-----------------------------------

-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

-- - monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- - upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- - upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- - once a customer churns they will no longer make payments

USE [Week 3 - Foodie-Fi];

WITH cte AS (
	SELECT *, 
		LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date, plan_id) [next_plan]
	FROM subscriptions
	),
cte2 AS (
	SELECT customer_id, p.plan_id, plan_name, 
		DATEADD(MONTH, value, start_date) [payment_date], price
	FROM cte
	JOIN plans p
		ON cte.plan_id = p.plan_id
	JOIN GENERATE_SERIES(0, 12, 1)
		ON DATEADD(MONTH, value, start_date) < 
		COALESCE(IIF(next_plan > '12-31-2020', NULL, next_plan), '12-31-2020')
	WHERE plan_name NOT IN ('trial', 'pro annual', 'churn')
	),
cte3 AS (
	SELECT customer_id, p.plan_id, plan_name, 
		DATEADD(YEAR, value, start_date) [payment_date], price
	FROM cte
	JOIN plans p
		ON cte.plan_id = p.plan_id
	JOIN GENERATE_SERIES(0, 12, 1)
		ON DATEADD(YEAR, value, start_date) < 
		COALESCE(IIF(next_plan > '12-31-2020', NULL, next_plan), '12-31-2020')
	WHERE plan_name NOT IN ('trial', 'basic monthly', 'pro monthly', 'churn')
	),
cte4 AS (
	SELECT *
		FROM cte2
	UNION
	SELECT * 
		FROM cte3
	)
SELECT customer_id, plan_id, plan_name, payment_date, 
	CASE
		WHEN LAG(plan_id) OVER(PARTITION BY customer_id ORDER BY payment_date, plan_id) <> plan_id
		AND DATEDIFF(DAY, LAG(payment_date) OVER(PARTITION BY customer_id ORDER BY payment_date, plan_id), payment_date) < 30
			THEN price - LAG(price) OVER(PARTITION BY customer_id ORDER BY payment_date, plan_id)
		ELSE price
	END AS [amount],
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date) AS [payment_order]
FROM cte4;
GO

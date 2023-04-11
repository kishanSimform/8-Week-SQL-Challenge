--------------------------------
-- B. Data Analysis Questions --
--------------------------------

USE [Week 3 - Foodie-Fi];


-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) [customer]
FROM subscriptions;
GO

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT DATEPART(MONTH, start_date) [Month], 
	COUNT(customer_id) [trial_plan]
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATEPART(MONTH, start_date)
ORDER BY Month;
GO

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plan_name, COUNT(*) [customer_count]
FROM subscriptions s
JOIN plans p
	ON s.plan_id = p.plan_id
WHERE DATEPART(YEAR, start_date) > 2020
GROUP BY plan_name;
GO

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(*) [churned_customer], 
	CAST((COUNT(*) *100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)) 
		AS DECIMAL(10,1)) [percentage]
FROM subscriptions
WHERE plan_id = 4;
GO

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte AS (
	SELECT customer_id, p.plan_id, start_date, plan_name, price, 
		LAG(p.plan_name) OVER(ORDER BY customer_id) [prev_plan]
	FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	)
SELECT COUNT(*) [churn_count],
	CAST(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) 
		AS NUMERIC) [churn_percentage]
FROM cte
WHERE plan_name = 'churn' AND
	prev_plan = 'trial';
GO

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH cte AS (
	SELECT customer_id, p.plan_id, start_date, plan_name, price, 
		LAG(p.plan_name) OVER(ORDER BY customer_id) [prev_plan]
	FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	),
cte2 AS (
	SELECT plan_id, COUNT(*) [plan_count]
	FROM subscriptions
	WHERE plan_id <> 0
	GROUP BY plan_id
	)
SELECT c.plan_name, COUNT(*) [customer_count], 
	CAST(ROUND((COUNT(*) * 100.0 / plan_count), 1)
		AS DECIMAL(10, 1)) [customer_percentage]
FROM cte c
JOIN cte2 c2
	ON c.plan_id = c2.plan_id
WHERE prev_plan = 'trial'
GROUP BY c.plan_name, plan_count;
GO

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH cte AS (
	SELECT customer_id, s.plan_id, plan_name, start_date,
		RANK() OVER(PARTITION BY customer_id
			ORDER BY start_date DESC) AS [rank]
	FROM subscriptions s
	JOIN plans p 
		ON s.plan_id = p.plan_id
	WHERE start_date <= '12-31-2020'
	),
cte2 AS (
	SELECT plan_id, COUNT(*) [plan_count]
	FROM subscriptions
	GROUP BY plan_id
	)
SELECT plan_name, COUNT(*) [customer_count],
	CAST(ROUND((COUNT(*) * 100.0 / plan_count), 1)
		AS DECIMAL(10, 1)) [customer_percentage]
FROM cte 
JOIN cte2
	ON cte.plan_id = cte2.plan_id
WHERE rank = 1
GROUP BY plan_name, plan_count;
GO

-- 8. How many customers have upgraded to an annual plan in 2020?
WITH cte AS (
	SELECT customer_id, p.plan_id, start_date, plan_name, price, 
		LAG(p.plan_name) OVER(ORDER BY customer_id) [prev_plan]
	FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	)
SELECT COUNT(DISTINCT customer_id) [customer_count]
FROM cte
WHERE plan_name = 'pro annual' AND
	prev_plan NOT IN ('pro annual', 'churn') AND
	start_date < '12-31-2020';
GO

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH cte AS (
	SELECT customer_id, p.plan_id, start_date FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	WHERE plan_name = 'trial'
	),
cte2 AS (
	SELECT customer_id, p.plan_id, start_date FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	WHERE plan_name = 'pro annual'
	)
SELECT AVG(DATEDIFF(DAY, cte.start_date, cte2.start_date)) [avg_day]
FROM cte 
JOIN cte2
	ON cte.customer_id = cte2.customer_id;
GO

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH cte AS (
	SELECT customer_id, p.plan_id, start_date FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	WHERE plan_name = 'trial'
	),
cte2 AS (
	SELECT customer_id, p.plan_id, start_date FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	WHERE plan_name = 'pro annual'
	),
cte3 AS (
	SELECT (DATEDIFF(DAY, cte.start_date, cte2.start_date)) [Diff]
	FROM cte
	JOIN cte2
		ON cte.customer_id = cte2.customer_id
	)
SELECT CAST((30 * FLOOR(Diff / 30)) AS VARCHAR) + ' - ' + CAST((30 * (FLOOR(Diff / 30) + 1)) AS VARCHAR) [day_range],
	COUNT(*) [customer_count], AVG(Diff) [avg_days]
FROM cte3
GROUP BY (30 * FLOOR(Diff / 30)) , (30 * (FLOOR(Diff / 30) + 1));
GO

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH cte AS (	
	SELECT customer_id, p.plan_id, start_date, plan_name, price, 
		LAG(p.plan_name) OVER(ORDER BY customer_id) [prev_plan]
	FROM subscriptions s
	JOIN plans p
	ON s.plan_id = p.plan_id
	)
SELECT COUNT(*) [count]
FROM cte 
WHERE plan_name = 'basic monthly' AND
	prev_plan = 'pro monthly';
GO

----------------------------------
-- D. Outside The Box Questions --
----------------------------------

-- The following are open ended questions which might be asked during a technical interview for this case study - 
-- there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

USE [Week 3 - Foodie-Fi];

-- 1. How would you calculate the rate of growth for Foodie-Fi?
WITH cte AS (
    SELECT DATETRUNC(MONTH, start_date) [MON], 
        COUNT(customer_id) [count]
    FROM subscriptions
    WHERE plan_id NOT IN (0,4)
    GROUP BY DATETRUNC(MONTH, start_date)
    )
SELECT *, (count - LAG(count) OVER(ORDER BY MON)) [customer_growth],
    CAST((count - LAG(count) OVER(ORDER BY MON)) * 100 / (LAG(count) OVER(ORDER BY MON)) AS VARCHAR) + '%' [customer_growth_perc]
FROM cte;
GO

/*
Here I have calculated customer_growth as compare to previous month's customers.
So we can see that negative percentage shown decrease in customer and positive percentage shown increase in customer.

In first 2 months, Jan - Feb 2020, growth was expanded. In June, July 2020, growth was almost contanst.
In last 4 months, means apparently 2021, number of customers are decreasing, so we can say that in that last 4 months, 
growth of company is dropping. 
*/

-- 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
SELECT * FROM (
	SELECT plan_name, customer_id, DATETRUNC(MONTH, start_date) [month]
	FROM subscriptions s
	JOIN plans p
		ON s.plan_id = p.plan_id
	) t
PIVOT (
	COUNT(customer_id)
	FOR plan_name IN 
		([trial], [basic monthly], [pro monthly], [pro annual], [churn])
	) AS piv
ORDER BY month;
GO

/*
This is the data that I would recommand for track over time to assess performance of overall business.
We can see all the plans and how many customers have purchased each plan in each months.
*/

-- 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
WITH cte AS (
	SELECT s.customer_id, p.plan_id, p.plan_name, start_date,
		LAG(p.plan_id) OVER(PARTITION BY customer_id ORDER BY p.plan_id) prev_plan
	FROM subscriptions s
	JOIN plans p
		ON p.plan_id = s.plan_id
	)
SELECT plan_id, plan_name, COUNT(*) churn_counts
FROM cte
WHERE prev_plan = 0
GROUP BY plan_id, plan_name;
GO

/*
Here we can see after trial plan only 37 customers have upgreaded to pro annual plan.
Around ~100 customers left subscription plan for this service, which impact very bad on this business.
Almost 50% customers continued with basic monthly plan, which will automatically converted after trial ends.
*/


WITH cte AS (
	SELECT s.customer_id, p.plan_id, p.plan_name, start_date,
		LEAD(p.plan_id) OVER(PARTITION BY customer_id ORDER BY p.plan_id) prev_plan
	FROM subscriptions s
	JOIN plans p
		ON p.plan_id = s.plan_id
	)
SELECT plan_id, plan_name, COUNT(*) churn_counts
FROM cte
WHERE prev_plan = 4
GROUP BY plan_id, plan_name;
GO

/*
This data is shown us after which plan customer have left service or cancel their subscriptions.
In this data, we can see that only 6 customers have cancelled pro annual plan. So it means pro annual plan has very low ratio of cancellation.
After trial, basic monthly plan and pro monthly plan, almost ~100 customers have cancelled their subscriptions.
*/

-- 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

-- What caused you to cancel the subscription?
-- How can we improve? (Optional)
-- How long had you been using the service?
-- What did you like about service?

-- 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

/*
According to the data, we can see that ~300 customer have churned their service with Foodie-Fi.
It means, till now Foodie-Fi have lost ~300 customers. Out of them 92 customers have churned their service directly after trial plan, which is bad for Foodie-Fi.
Good thing is that ~200 customers upgreaded to pro annual service. And also no one has downgreded their plan from pro monthly to basic.

So here, I thought that the main problem is with basic monthly and pro monthly subscriptions.
Because half of the customers have just started basic monthly plan which is by default after trial plan.
Here pro annual plan is most effective, so reducing proce of pro annual subscription can lead to growth of customers. 
Because there are very less number of customers who have churned their subscription after pro annual plan.
*/

-----------------------
-- 4. Bonus Question --
-----------------------

/*
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

- region
- platform
- age_band
- demographic
- customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?
*/

USE [Week 5 - Data Mart];

-- REGION 

WITH cte AS (
	SELECT region,
		SUM(CASE
			WHEN week_date_ BETWEEN CAST(DATEADD(WEEK, -12, '2020-06-15') AS date) AND '2020-06-15'
				THEN CAST(sales AS BIGINT)
			END) AS [before],
		SUM(CASE
			WHEN week_date_ BETWEEN '2020-06-15' AND CAST(DATEADD(WEEK, 12, '2020-06-15') AS date)
				THEN CAST(sales AS BIGINT)
			END) AS [after]
	FROM cleaned_weekly_sales
	group by region
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte
ORDER BY change_percentage;
GO

/*
Here we can see that ASIA has highest negetive impact as compare to all others.
EUROPE has lowest negative impact.
*/


-- PLATFORM

WITH cte AS (
	SELECT platform,
		SUM(CASE
			WHEN week_date_ BETWEEN CAST(DATEADD(WEEK, -12, '2020-06-15') AS date) AND '2020-06-15'
				THEN CAST(sales AS BIGINT)
			END) AS [before],
		SUM(CASE
			WHEN week_date_ BETWEEN '2020-06-15' AND CAST(DATEADD(WEEK, 12, '2020-06-15') AS date)
				THEN CAST(sales AS BIGINT)
			END) AS [after]
	FROM cleaned_weekly_sales
	group by platform
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte
ORDER BY change_percentage;
GO

/*
Here Retail has more negative impact compare to Shopify.
*/


--  AGE BAND

WITH cte AS (
	SELECT age_band,
		SUM(CASE
			WHEN week_date_ BETWEEN CAST(DATEADD(WEEK, -12, '2020-06-15') AS date) AND '2020-06-15'
				THEN CAST(sales AS BIGINT)
			END) AS [before],
		SUM(CASE
			WHEN week_date_ BETWEEN '2020-06-15' AND CAST(DATEADD(WEEK, 12, '2020-06-15') AS date)
				THEN CAST(sales AS BIGINT)
			END) AS [after]
	FROM cleaned_weekly_sales
	group by age_band
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte
ORDER BY change_percentage;
GO

/*
Unknown age group has highest negative impact on sales. 
After that Middle Aged group has second highest negative impact.
*/


-- DEMOGRAPHIC

WITH cte AS (
	SELECT demographic,
		SUM(CASE
			WHEN week_date_ BETWEEN CAST(DATEADD(WEEK, -12, '2020-06-15') AS date) AND '2020-06-15'
				THEN CAST(sales AS BIGINT)
			END) AS [before],
		SUM(CASE
			WHEN week_date_ BETWEEN '2020-06-15' AND CAST(DATEADD(WEEK, 12, '2020-06-15') AS date)
				THEN CAST(sales AS BIGINT)
			END) AS [after]
	FROM cleaned_weekly_sales
	group by demographic
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte
ORDER BY change_percentage;
GO

/*
Unknown demographic group has highest negative impact on sales.
After that families and than couples.
*/


-- CUSTOMER TYPE

WITH cte AS (
	SELECT customer_type,
		SUM(CASE
			WHEN week_date_ BETWEEN CAST(DATEADD(WEEK, -12, '2020-06-15') AS date) AND '2020-06-15'
				THEN CAST(sales AS BIGINT)
			END) AS [before],
		SUM(CASE
			WHEN week_date_ BETWEEN '2020-06-15' AND CAST(DATEADD(WEEK, 12, '2020-06-15') AS date)
				THEN CAST(sales AS BIGINT)
			END) AS [after]
	FROM cleaned_weekly_sales
	group by customer_type
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte
ORDER BY change_percentage;
GO

/*
Here, Guest type of customer has highest negative impact on sales as compare to others.
*/


/*
Conclusion
So, we can say that REGION have more negative impact as compare to other all areas of business and in it ASIA has highest negative impact.
After that CUSTOMER TYPE is more important to take a look because Guest type of customer have high negative impact on sales.

Recommandation 
As we can see that in platform area, Shopify has lowest negative impact as compare to all other aspects.
So I think Danny's team should give more focus on online platform Shopify because maybe it will lead to growth of business.
*/
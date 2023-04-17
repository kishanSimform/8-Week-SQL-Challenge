--------------------------------
-- 3. Before & After Analysis --
--------------------------------

/*
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
- What about the entire 12 weeks before and after?
- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
*/

USE [Week 5 - Data Mart];

-- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
WITH cte AS (
	SELECT 
		SUM(CASE
			WHEN week_date_ BETWEEN CAST(DATEADD(WEEK, -4, '2020-06-15') AS date) AND '2020-06-15'
				THEN CAST(sales AS BIGINT)
			END) AS [before],
		SUM(CASE
			WHEN week_date_ BETWEEN '2020-06-15' AND CAST(DATEADD(WEEK, 4, '2020-06-15') AS date)
				THEN CAST(sales AS BIGINT)
			END) AS [after]
	FROM cleaned_weekly_sales
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte;
GO

-- What about the entire 12 weeks before and after?
WITH cte AS (
	SELECT
		SUM(CASE
			WHEN week_date_ BETWEEN CAST(DATEADD(WEEK, -12, '2020-06-15') AS date) AND '2020-06-15'
				THEN CAST(sales AS BIGINT)
			END) AS [before],
		SUM(CASE
			WHEN week_date_ BETWEEN '2020-06-15' AND CAST(DATEADD(WEEK, 12, '2020-06-15') AS date)
				THEN CAST(sales AS BIGINT)
			END) AS [after]
	FROM cleaned_weekly_sales
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte;
GO

-- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

-- Before and After 4 weeks of 15-06
WITH cte AS(
	SELECT calender_year, CAST(CAST(calender_year AS VARCHAR)+'-06-15' AS date) [date_],
		CAST(DATEADD(WEEK, -4, CAST(CAST(calender_year AS VARCHAR)+'-06-15' AS date)) AS DATE) [date_before],
		CAST(DATEADD(WEEK, 4, CAST(CAST(calender_year AS VARCHAR)+'-06-15' AS date)) AS DATE) [date_after]
	FROM cleaned_weekly_sales
	GROUP BY calender_year
	),
cte2 AS (
	SELECT cte.calender_year ,
		SUM(CASE
				WHEN week_date_ BETWEEN date_before AND date_
					THEN CAST(sales AS BIGINT)
				END) AS [before],
		SUM(CASE
				WHEN week_date_ BETWEEN date_ AND date_after
					THEN CAST(sales AS BIGINT)
				END) AS [after]
	FROM cte, cleaned_weekly_sales
	GROUP BY cte.calender_year
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte2
ORDER BY calender_year;
GO


-- Before and After 12 weeks of 15-06
WITH cte AS(
	SELECT calender_year, CAST(CAST(calender_year AS VARCHAR)+'-06-15' AS date) [date_],
		CAST(DATEADD(WEEK, -12, CAST(CAST(calender_year AS VARCHAR)+'-06-15' AS date)) AS DATE) [date_before],
		CAST(DATEADD(WEEK, 12, CAST(CAST(calender_year AS VARCHAR)+'-06-15' AS date)) AS DATE) [date_after]
	FROM cleaned_weekly_sales
	GROUP BY calender_year
	),
cte2 AS (
	SELECT cte.calender_year ,
		SUM(CASE
				WHEN week_date_ BETWEEN date_before AND date_
					THEN CAST(sales AS BIGINT)
				END) AS [before],
		SUM(CASE
				WHEN week_date_ BETWEEN date_ AND date_after
					THEN CAST(sales AS BIGINT)
				END) AS [after]
	FROM cte, cleaned_weekly_sales
	GROUP BY cte.calender_year
	)
SELECT *,
	(after - before) AS [diff],
	CAST(ROUND((after - before) * 100.0 / before , 2) AS DECIMAL(10,2)) [change_percentage]
FROM cte2
ORDER BY calender_year;
GO

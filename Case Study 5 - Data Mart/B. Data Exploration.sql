-------------------------
-- 2. Data Exploration --
-------------------------

USE [Week 5 - Data Mart];

-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT DATENAME(WEEKDAY, week_date_) [week_day]
FROM cleaned_weekly_sales;
GO

-- 2. What range of week numbers are missing from the dataset?
SELECT value
FROM GENERATE_SERIES(1,53)
WHERE value NOT IN (
	SELECT DISTINCT week_number
	FROM cleaned_weekly_sales
	);
GO

-- 3. How many total transactions were there for each year in the dataset?
SELECT calender_year, 
	SUM(CAST(transactions AS BIGINT)) [total_transaction]
FROM cleaned_weekly_sales
GROUP BY calender_year;
GO

-- 4. What is the total sales for each region for each month?
SELECT region, 
	SUM(CAST(sales AS BIGINT)) [total_sales]
FROM cleaned_weekly_sales
GROUP BY region
ORDER BY region;
GO

-- 5. What is the total count of transactions for each platform?
SELECT platform, 
	SUM(CAST(transactions AS BIGINT)) [total_transaction]
FROM cleaned_weekly_sales
GROUP BY platform;
GO

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH cte AS (
	SELECT calender_year, month_number,
		SUM(CASE
			WHEN platform = 'Shopify' 
				THEN CAST(sales AS BIGINT) 
		END) AS [shopify_sales], 
		SUM(CASE
			WHEN platform = 'Retail' 
				THEN CAST(sales AS BIGINT) 
		END) AS [retail_sales],
		SUM(CAST(sales AS BIGINT)) AS [total_sales]
	FROM cleaned_weekly_sales
	GROUP BY calender_year, month_number
	)
SELECT calender_year, month_number, 
	CAST(ROUND((retail_sales * 100.0 / total_sales), 2) 
		AS decimal(10,2)) [retail_percentage],
	CAST(ROUND((shopify_sales * 100.0 / total_sales), 2) 
		AS decimal(10,2)) [shopify_percentage]
FROM cte
ORDER BY calender_year, month_number;
GO

-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH cte AS (
	SELECT calender_year,
		SUM(CASE
			WHEN demographic = 'Couples'
				THEN CAST(sales AS BIGINT) 
		END) AS [couples_sales], 
		SUM(CASE
			WHEN demographic = 'Families'
				THEN CAST(sales AS BIGINT) 
		END) AS [families_sales], 
		SUM(CASE
			WHEN demographic = 'unknown'
				THEN CAST(sales AS BIGINT) 
		END) AS [unknown_sales], 
		SUM(CAST(sales AS BIGINT)) AS [total_sales]
	FROM cleaned_weekly_sales
	GROUP BY calender_year
	)
SELECT calender_year, 
	CAST(ROUND((couples_sales * 100.0 / total_sales), 2) 
		AS decimal(10,2)) [couples_percentage],
	CAST(ROUND((families_sales * 100.0 / total_sales), 2) 
		AS decimal(10,2)) [families_percentage],
	CAST(ROUND((unknown_sales * 100.0 / total_sales), 2) 
		AS decimal(10,2)) [unknown_percentage]
FROM cte
ORDER BY calender_year;
GO

-- 8. Which age_band and demographic values contribute the most to Retail sales?
WITH cte AS (
	SELECT SUM(CAST(sales AS BIGINT)) [total_sales]
	FROM cleaned_weekly_sales 
	WHERE platform = 'Retail'
	)
SELECT age_band, demographic,
	CAST(ROUND(SUM(CAST(sales AS BIGINT)) * 100.0 / (SELECT total_sales FROM cte), 2)
		AS DECIMAL(10,2)) AS [sales_by_segment]
FROM cleaned_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY sales_by_segment DESC;
GO

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- No, we can not use it because it would give incorrect answer, as shown below.

SELECT calender_year, platform,
	(SUM(CAST(sales AS BIGINT)) / SUM(CAST(transactions AS BIGINT))) [correct_avg_transactions],
	CAST(ROUND(AVG(avg_transaction), 0) AS DECIMAL) [incorrect_avg_transactions]
FROM cleaned_weekly_sales
GROUP BY calender_year, platform
ORDER BY calender_year, platform;
GO

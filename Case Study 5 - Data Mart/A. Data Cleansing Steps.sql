-----------------------------
-- 1. Data Cleansing Steps --
-----------------------------

USE [Week 5 - Data Mart];

-- In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

/*
- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

	segment		age_band
	1			Young Adults
	2			Middle Aged
	3 or 4		Retirees

- Add a new demographic column using the following mapping for the first letter in the segment values:

	segment		demographic
	C			Couples
	F			Families

- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
*/

DROP TABLE IF EXISTS cleaned_weekly_sales;

WITH cte AS (
	SELECT *, CONVERT(date, week_date, 3) [week_date_]
	FROM weekly_sales
	)
SELECT
	[week_date_],
	DATEPART(WEEK, week_date_) [week_number],
	DATEPART(MONTH, week_date_) [month_number],
	DATEPART(YEAR, week_date_) [calender_year],
	region,
	platform,
	customer_type,
	CASE 
		WHEN segment = 'null' THEN 'unknown'
		ELSE segment
	END AS [segment_],
	CASE
		WHEN segment LIKE '%1%' THEN 'Young Adults'
		WHEN segment LIKE '%2%' THEN 'Middle Aged'
		WHEN segment LIKE '%3%' OR segment LIKE '%4%' THEN 'Retirees'
		ELSE 'unknown'
	END AS [age_band],
	CASE
		WHEN segment LIKE 'C%' THEN 'Couples'
		WHEN segment LIKE 'F%' THEN 'Families'
		ELSE 'unknown'
	END AS [demographic],
	sales,
	transactions,
	CAST(ROUND((sales / transactions), 2) AS DECIMAL(10,2)) avg_transaction
INTO cleaned_weekly_sales
FROM cte;
GO

SELECT *
FROM cleaned_weekly_sales;
GO
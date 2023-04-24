------------------------------------
-- Data Exploration and Cleansing --
------------------------------------

USE [Week 8 - Fresh Segments];

-- 1. Update the interest_metrics table by modifying the month_year column to be a date data type with the start of the month.
ALTER TABLE interest_metrics
ALTER COLUMN month_year VARCHAR(10);
GO

UPDATE interest_metrics
SET month_year = CONVERT(DATE, '01-' + month_year, 105); 
GO

ALTER TABLE interest_metrics
ALTER COLUMN month_year DATE;
GO

SELECT month_year 
FROM interest_metrics;
GO

-- 2. What is count of records in the interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT DATETRUNC(MONTH, month_year) [month], COUNT(*) [count]
FROM interest_metrics
GROUP BY DATETRUNC(MONTH, month_year)
ORDER BY month;
GO

-- 3. What do you think we should do with these null values in the interest_metrics?
SELECT CAST(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM interest_metrics), 2) AS DECIMAL(10,2))
FROM interest_metrics
WHERE CAST(interest_id AS VARCHAR) IS NULL;
GO

/*
There are 8.36% interest_ids are null, which is not that large number, so we can drop it.
And it interest_id is not given than other values won't matters.
So we can drop these rows.
*/

DELETE FROM interest_metrics
WHERE interest_id IS NULL;
GO

SELECT * 
FROM interest_metrics;
GO

-- 4. How many interest_id values exist in the interest_metrics table but not in the interest_map table? What about the other way around?
SELECT COUNT(interest_id) [interest_id]
FROM interest_metrics
WHERE interest_id NOT IN (
	SELECT id
	FROM interest_map
	);
GO

SELECT COUNT(id) [interest_id]
FROM interest_map
WHERE id NOT IN (
	SELECT DISTINCT CAST(interest_id AS INT)
	FROM interest_metrics
	);
GO

-- 5. Summarise the id values in the interest_map by its total record count in this table.
SELECT COUNT(id) [total_record]
FROM interest_map;
GO

SELECT interest_id, 
	CAST(interest_name AS varchar) [interest_name], 
	COUNT(interest_id) [total_record]
FROM interest_metrics im
JOIN interest_map i	
	ON im.interest_id = i.id
GROUP BY interest_id, CAST(interest_name AS varchar)
ORDER BY CAST(interest_id AS INT);
GO

-- 6. What sort of table join should we perform for our analysis and why? 
-- Check your logic by checking the rows where interest_id = 21246 in your joined output and 
-- include all columns from interest_metrics and all columns from interest_map except from the id column.
SELECT a.*,
	interest_name,
	interest_summary,
	created_at,
	last_modified
FROM interest_metrics a
JOIN interest_map b 
	ON a.interest_id = b.id
WHERE a.interest_id = '21246';
GO


-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the interest_map table? 
-- Do you think these values are valid and why?
SELECT *
FROM interest_metrics a
JOIN interest_map b 
	ON a.interest_id = b.id
WHERE month_year < created_at;
GO
-- Yes there are 188 rows which have created_at > month year, because in month_year at the time of table creation
-- there was no day specified to month_year but in first cleaning task we have given explicit day of 01 to each month_year value.
-----------------------
-- Interest Analysis --
-----------------------

USE [Week 8 - Fresh Segments];

-- 1. Which interests have been present in all month_year dates in our dataset?
WITH cte AS (
	SELECT interest_id, 
	  COUNT(DISTINCT month_year) AS total_months
	FROM interest_metrics ,interest_map
	WHERE month_year IS NOT NULL
	GROUP BY interest_id
	)
SELECT c.interest_id, interest_name
FROM cte c
JOIN interest_map i
	ON c.interest_id = i.id
WHERE c.total_months = (
	SELECT COUNT(DISTINCT month_year)
	FROM interest_metrics
	);
GO

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months 
-- which total_months value passes the 90% cumulative percentage value?
WITH cte AS (
	SELECT interest_id, COUNT(DISTINCT month_year) [total_month]
	FROM interest_metrics
	GROUP BY interest_id
	),
cte2 AS (
	SELECT total_month, COUNT(interest_id) [total_interest]
	FROM cte
	GROUP BY total_month
	)
SELECT *, CAST(ROUND(SUM(total_interest) OVER(ORDER BY total_month DESC) * 100.0 / SUM(total_interest) OVER(), 2) AS decimal(10,2)) [cume_percentage]
FROM cte2
ORDER BY total_month DESC;
GO

/*
After total_month value 7, cume_percentage passes 90%.
*/

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question 
-- how many total data points would we be removing?
WITH cte AS (
	SELECT interest_id, COUNT(DISTINCT month_year) [total_month]
	FROM interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) < 7
	)
SELECT COUNT(interest_id) [count]
FROM cte;
GO

-- 4. Does this decision make sense to remove these data points from a business perspective? 
-- Use an example where there are all 14 months present to a removed interest example for your arguments 
-- think about what it means to have less months present from a segment perspective.
WITH cte AS (
	SELECT month_year, COUNT(interest_id) [total_interest]
	FROM interest_metrics
	WHERE month_year IS NOT NULL AND 
		interest_id NOT IN (
		SELECT interest_id
		FROM interest_metrics
		GROUP BY interest_id
		HAVING COUNT(DISTINCT month_year) < 7
		)
	GROUP BY month_year
	),
cte2 AS (
	SELECT im.month_year, total_interest, COUNT(interest_id) [excluded_interest]
	FROM interest_metrics im
	JOIN cte
		ON im.month_year = cte.month_year
	WHERE im.month_year IS NOT NULL AND 
		interest_id NOT IN (
		SELECT interest_id
		FROM interest_metrics
		GROUP BY interest_id
		HAVING COUNT(DISTINCT month_year) > 6
		)
	GROUP BY im.month_year, total_interest
	)
SELECT *, CAST(ROUND(excluded_interest * 100.0 / total_interest, 2) AS DECIMAL(10,2)) [excluded_percentage]
FROM cte2
ORDER BY month_year;
GO

-- 5. After removing these interests - how many unique interests are there for each month?
SELECT
  month_year,
  COUNT(interest_id) AS number_of_interests
FROM
  interest_metrics AS im
WHERE
  month_year IS NOT NULL AND
  interest_id IN (
    SELECT interest_id
    FROM interest_metrics
    GROUP BY interest_id
    HAVING COUNT(DISTINCT month_year) > 6)
GROUP BY month_year
ORDER BY month_year;
GO

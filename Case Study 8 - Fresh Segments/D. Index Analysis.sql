---------------------
-- Index Analysis --
--------------------

/*
The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.
*/

USE [Week 8 - Fresh Segments];

-- 1. What is the top 10 interests by the average composition for each month?
DROP TABLE IF EXISTS #top_10_interest;

WITH cte AS (
	SELECT *, composition * 1.0 / index_value [avg_composition]
	FROM interest_metrics
	),
cte2 AS (
	SELECT interest_id, month_year, avg_composition,
		RANK() OVER (PARTITION BY month_year ORDER BY avg_composition DESC) [rank]
	FROM cte
	WHERE month_year IS NOT NULL
	)
SELECT month_year, interest_id, interest_name, rank,
	CAST(ROUND(avg_composition, 2) AS DECIMAL(10,2)) [avg_composition]
INTO #top_10_interest
FROM cte2
JOIN interest_map i
	ON cte2.interest_id = i.id
WHERE rank <= 10
ORDER BY month_year;
GO

SELECT month_year, interest_id, interest_name, avg_composition
FROM #top_10_interest;
GO

-- 2. For all of these top 10 interests - which interest appears the most often?
WITH cte AS (	
	SELECT CAST(interest_name AS varchar) [interest_name], 
		COUNT(interest_id) [count_],
		RANK() OVER (ORDER BY COUNT(interest_id) DESC) [rank]
	FROM #top_10_interest
	GROUP BY CAST(interest_name AS varchar)
	)
SELECT interest_name, count_
FROM cte 
WHERE rank = 1;
GO

-- 3. What is the average of the average composition for the top 10 interests for each month?
SELECT month_year, AVG(avg_composition) [avg_of_avg_comp]
FROM #top_10_interest
GROUP BY month_year;
GO

-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and 
-- include the previous top ranking interests in the same output shown below.
WITH cte AS (	
	SELECT month_year, interest_name, 
		avg_composition [max_index_composition],
		CAST(AVG(avg_composition) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS decimal(10,2)) [3_month_moving_avg],
		CONCAT(LAG(interest_name) OVER (ORDER BY month_year), ': ', LAG(avg_composition) OVER (ORDER BY month_year)) [1_month_ago],
		CONCAT(LAG(interest_name, 2) OVER (ORDER BY month_year) , ': ', LAG(avg_composition, 2) OVER (ORDER BY month_year)) [2_month_ago]
	FROM #top_10_interest 
	WHERE rank = 1
	)
SELECT * 
FROM cte
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01'
ORDER BY month_year;
GO

-- 5. Provide a possible reason why the max average composition might change from month to month? 
-- Could it signal something is not quite right with the overall business model for Fresh Segments?

/*
I think it's because of seasonal. People make plans for trips when summer is coming which is time of holiday.
Other than that time work is first priority. So this is because of change in season.
Another possible reason can be that interests' may have changed time to time. 
So, because of this reason composition might change from month to month.
*/
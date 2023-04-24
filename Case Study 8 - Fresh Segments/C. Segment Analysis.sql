----------------------
-- Segment Analysis --
----------------------

USE [Week 8 - Fresh Segments];

DROP TABLE IF EXISTS #filtered_interest_metrics;

SELECT * 
INTO #filtered_interest_metrics
FROM interest_metrics
WHERE interest_id NOT IN (
    SELECT interest_id
    FROM interest_metrics
    GROUP BY interest_id
    HAVING COUNT(DISTINCT month_year) < 6
	);
GO

SELECT * 
FROM #filtered_interest_metrics;
GO

-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, 
-- which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? 
-- Only use the maximum composition value for each interest but you must keep the corresponding month_year

WITH cte AS (
	SELECT month_year, interest_id, composition, 
	MAX(composition) OVER(PARTITION BY interest_id) [max_composition]
	FROM interest_metrics
	)
SELECT TOP 10
	month_year, interest_id, interest_name, composition, max_composition
FROM cte
JOIN interest_map im
	ON cte.interest_id = im.id
WHERE composition = max_composition
ORDER BY max_composition DESC;
GO

WITH cte AS (
	SELECT month_year, interest_id, composition, 
	MIN(composition) OVER(PARTITION BY interest_id) [min_composition]
	FROM interest_metrics
	)
SELECT TOP 10
	month_year, interest_id, interest_name, composition, min_composition
FROM cte
JOIN interest_map im
	ON cte.interest_id = im.id
WHERE composition = min_composition
ORDER BY min_composition;
GO

-- 2. Which 5 interests had the lowest average ranking value?
SELECT TOP 5 
	interest_id, CAST(interest_name AS varchar) [interest_name], AVG(ranking*1.0) [avg_rank]
FROM #filtered_interest_metrics fim
JOIN interest_map im
	ON fim.interest_id = im.id
GROUP BY interest_id, CAST(interest_name AS varchar)
ORDER BY avg_rank DESC;
GO

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
SELECT TOP 5 
	interest_id, CAST(interest_name AS varchar) [interest_name], STDEV(percentile_ranking*1.0) [std_dev_percentile_rank]
FROM #filtered_interest_metrics fim
JOIN interest_map im
	ON fim.interest_id = im.id
GROUP BY interest_id, CAST(interest_name AS varchar)
ORDER BY std_dev_percentile_rank DESC;
GO

-- 4. For the 5 interests found in the previous question - 
-- what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? 
-- Can you describe what is happening for these 5 interests?

WITH cte AS (
	SELECT TOP 5 
		interest_id,
		CAST(interest_name AS varchar) [interest_name], 
		STDEV(percentile_ranking*1.0) [std_dev_percentile_rank]
	FROM #filtered_interest_metrics fim
	JOIN interest_map im
		ON fim.interest_id = im.id
	GROUP BY interest_id, CAST(interest_name AS varchar)
	ORDER BY std_dev_percentile_rank DESC
	)
SELECT i.interest_id, interest_name,
	MIN(percentile_ranking) [min_percentile_ranking],
	MAX(percentile_ranking) [max_percentile_ranking]
FROM interest_metrics i
JOIN cte c
	ON i.interest_id = c.interest_id
GROUP BY i.interest_id, interest_name;
GO

-- 5. How would you describe our customers in this segment based off their composition and ranking values? 
-- What sort of products or services should we show to these customers and what should we avoid?

 /*
Customers in this market category enjoy travelling, some may be business travellers, they seek a luxurious lifestyle, and they participate in sports. 
Instead of focusing on the budget category or any products or services connected to unrelated hobbies like computer games or astrology, 
we should highlight those that are relevant to luxury travel or a luxurious lifestyle.
Hence, in general, we must concentrate on the interests with high composition values, 
but we also must monitor this metric to determine when clients become disinterested in a particular subject.
*/

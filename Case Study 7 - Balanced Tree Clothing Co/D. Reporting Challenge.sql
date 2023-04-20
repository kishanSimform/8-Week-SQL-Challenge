-------------------------
-- Reporting Challenge --
-------------------------

/*
Write a single SQL script that combines all of the previous questions into a scheduled report that 
the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - 
but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need -
but be sure to explicitly reference which table outputs relate to which question for full marks :)
*/

USE [Week 7 - Balanced Tree Clothing Co.];

DROP PROCEDURE IF EXISTS #sp_product_analysis;
GO

CREATE PROCEDURE #sp_product_analysis 
	@month INT,
	@year INT
AS	
	
	-- top 3 products by total revenue before discount

	PRINT '1. Top 3 products by total revenue before discount.
	';

	WITH top_3_product_by_revenue AS (	
		SELECT product_name, 
			SUM(qty * p.price) [revenue],
			DENSE_RANK() OVER (ORDER BY SUM(qty * p.price) DESC) [rank]
		FROM sales s
		JOIN product_details p
			ON s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		GROUP BY product_name
		)
	SELECT product_name, revenue
	FROM top_3_product_by_revenue 
	WHERE rank <= 3;


	-- total quantity, revenue and discount for each segment

	PRINT '2. Total quantity, revenue and discount for each segment.
	';

	SELECT segment_name, 
		SUM(qty) [total_quantity],
		SUM(qty * p.price) [total_revenue],
		SUM(qty * p.price * CAST(discount / 100.0 AS decimal(10,2))) [total_discount]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
	GROUP BY segment_name;


	-- top selling product for each segment

	PRINT '3. Top selling product for each segment.
	';

	WITH top_selling_product_by_segment AS (	
		SELECT product_name, segment_name, 
			SUM(qty) [total_sell],
			DENSE_RANK() OVER (PARTITION BY segment_name ORDER BY SUM(qty) DESC) [rank]
		FROM sales s
		JOIN product_details p
			ON s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		GROUP BY product_name, segment_name
		)
	SELECT product_name, segment_name, total_sell
	FROM top_selling_product_by_segment
	WHERE RANK = 1;


	-- total quantity, revenue and discount for each category

	PRINT '4. Total quantity, revenue and discount for each category.
	';

	SELECT category_name, 
		SUM(qty) [total_quantity],
		SUM(qty * p.price) [total_revenue],
		SUM(qty * p.price * CAST(discount / 100.0 AS decimal(10,2))) [total_discount]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
	GROUP BY category_name;
	

	-- top selling product for each category

	PRINT '5. Top selling product for each category.
	';

	WITH top_selling_product_by_category AS (	
		SELECT product_name, category_name, 
			SUM(qty) [total_sell],
			DENSE_RANK() OVER (PARTITION BY category_name ORDER BY SUM(qty) DESC) [rank]
		FROM sales s
		JOIN product_details p
			ON s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		GROUP BY product_name, category_name
		)
	SELECT product_name, category_name, total_sell
	FROM top_selling_product_by_category
	WHERE RANK = 1;


	-- percentage split of revenue by product for each segment

	PRINT '6. Percentage split of revenue by product for each segment.
	';

	WITH percentage_revenue_by_product_for_segment AS (
		SELECT product_name, segment_name,
			SUM(qty * p.price) [revenue]
		FROM sales s
		JOIN product_details p
			ON s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		GROUP BY product_name, segment_name
		)
	SELECT product_name, segment_name, revenue, 
		CAST(ROUND(revenue * 100.0 / (SUM(revenue) OVER(PARTITION BY segment_name)), 2) AS decimal(10,2)) [revenue_percentage_by_segment]
	FROM percentage_revenue_by_product_for_segment;


	-- percentage split of revenue by segment for each category

	PRINT '7. Percentage split of revenue by segment for each category.
	';

	WITH percentage_revenue_by_segment_for_category AS (
		SELECT segment_name, category_name,
			SUM(qty * p.price) [revenue]
		FROM sales s
		JOIN product_details p
			ON s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		GROUP BY segment_name, category_name
		)
	SELECT segment_name, category_name, revenue, 
		CAST(ROUND(revenue * 100.0 / (SUM(revenue) OVER(PARTITION BY category_name)), 2) AS decimal(10,2)) [revenue_percentage_by_category]
	FROM percentage_revenue_by_segment_for_category;


	-- percentage split of total revenue by category

	PRINT '8. Percentage split of total revenue by category.
	';

	WITH cte AS (
		SELECT SUM(qty * price) [revenue]
		FROM sales 
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		)
	SELECT category_name,
			CAST(ROUND(SUM(qty * p.price) * 100.0 / (SELECT revenue FROM cte), 2) AS DECIMAL(10,2)) [revenue]
		FROM sales s
		JOIN product_details p
			ON s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
		AND DATEPART(YEAR, start_txn_time) = @year
	GROUP BY category_name;


	-- total transaction “penetration” for each product 
	-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

	PRINT '9. Total transaction “penetration” for each product.
	';

	WITH cte AS (
		SELECT COUNT(DISTINCT txn_id) [txn]
		FROM sales
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		)
	SELECT product_name,
      	  CAST(ROUND(COUNT(product_name) * 100.0 / (SELECT txn FROM cte), 2) AS DECIMAL(10,2)) AS [product_penetration]
	FROM sales s
	JOIN product_details p
		ON s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
	GROUP BY product_name
	ORDER BY product_penetration DESC;


	-- most common combination of at least 1 quantity of any 3 products in a 1 single transaction

	PRINT '10. Most common combination of at least 1 quantity of any 3 products in a 1 single transaction.
	';

	WITH cte AS (
		SELECT s.prod_id, txn_id, product_name
		FROM sales s
		JOIN product_details p
			ON s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
			AND DATEPART(YEAR, start_txn_time) = @year
		),
	cte2 AS (
		SELECT
			c1.product_name [product_1],
			c2.product_name [product_2], 
			c3.product_name [product_3], 
			COUNT(c1.txn_id) [txn_count],
			DENSE_RANK() OVER (ORDER BY COUNT(c1.txn_id) DESC) [rank]
		FROM cte c1
		JOIN cte c2
			ON c1.txn_id = c2.txn_id and c1.prod_id < c2.prod_id
		JOIN cte c3
			ON c2.txn_id = c3.txn_id and c2.prod_id < c3.prod_id
		GROUP BY c1.product_name, c2.product_name, c3.product_name
		)
	SELECT product_1, product_2, product_3, txn_count
	FROM cte2
	WHERE rank = 1;

GO


 EXECUTE #sp_product_analysis @month = 1, @year = 2021;
 GO
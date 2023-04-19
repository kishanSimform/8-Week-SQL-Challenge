-------------------------------
-- High Level Sales Analysis --
-------------------------------

USE [Week 7 - Balanced Tree Clothing Co.];

-- 1. What was the total quantity sold for all products?
SELECT SUM(qty) [total_quantity]
FROM sales;
GO

-- - For each product
SELECT product_name, SUM(qty) [total_quantity]
FROM product_details p
JOIN sales s
	ON p.product_id = s.prod_id
GROUP BY product_name;
GO

-- 2. What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) [total_revenue]
FROM sales;
GO

-- For each product
SELECT product_name, SUM(qty * p.price) [total_revenue]
FROM product_details p
JOIN sales s
	ON p.product_id = s.prod_id
GROUP BY product_name;
GO

-- 3. What was the total discount amount for all products?
SELECT SUM(qty * price * CAST(discount / 100.0 AS decimal(10,2))) [discount_price]
FROM sales;
GO

-- For each product
SELECT product_name, SUM(qty * p.price * CAST(discount / 100.0 AS decimal(10,2))) [discount_price]
FROM product_details p
JOIN sales s
	ON p.product_id = s.prod_id
GROUP BY product_name;
GO
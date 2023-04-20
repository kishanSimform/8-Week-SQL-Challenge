---------------------
-- Bonus Challenge --
---------------------

USE [Week 7 - Balanced Tree Clothing Co.];

-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.
-- Hint: you may want to consider using a recursive CTE to solve this problem!

SELECT 
	product_id,
	price, 
	ph3.level_text + ' ' + ph2.level_text + ' - ' + ph1.level_text [product_name],
	ph1.id [category_id], 
	ph2.id [segment_id], 
	ph3.id [style_id],
	ph1.level_text [category_name],
	ph2.level_text [segment_name],
	ph3.level_text [style_name]
FROM product_hierarchy ph1
JOIN product_hierarchy ph2
	ON ph1.id = ph2.parent_id 
		AND ph1.level_name = 'Category'
JOIN product_hierarchy ph3
	ON ph2.id = ph3.parent_id 
		AND ph2.level_name = 'Segment'
JOIN product_prices pp
	ON ph3.id = pp.id
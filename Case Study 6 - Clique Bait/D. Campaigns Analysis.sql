---------------------------
-- 3. Campaigns Analysis --
---------------------------

USE [Week 6 - Clique Bait];

/*
Generate a table that has 1 single row for every unique visit_id record and has the following columns:

- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

Use the subsequent dataset to generate at least 5 insights for the Clique Bait team
- bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.
*/

DROP TABLE IF EXISTS #campaign_analysis;

SELECT user_id, e.visit_id, MIN(event_time) AS [visit_start_time],
	SUM(CASE
		WHEN event_name = 'Page View' THEN 1
	END) AS [page_views],
	SUM(CASE
		WHEN event_name = 'Add to Cart' THEN 1
		ELSE 0
	END) AS [cart_adds],
	SUM(CASE
		WHEN event_name = 'Purchase' THEN 1
		ELSE 0
	END) AS [purchase],
	campaign_name,
	SUM(CASE
		WHEN event_name = 'Ad Impression' THEN 1
		ELSE 0
	END) AS [impression],
	SUM(CASE
		WHEN event_name = 'Ad Click' THEN 1
		ELSE 0
	END) AS [click],
	STRING_AGG(CASE
		WHEN event_name = 'Add to Cart' AND p.page_id NOT IN (1, 2, 12, 13)
			THEN page_name
		END, ', ') AS [cart_products]
INTO #campaign_analysis
FROM events e
JOIN users u
	ON u.cookie_id = e.cookie_id
JOIN event_identifier ei
	ON e.event_type = ei.event_type
JOIN page_hierarchy p
	ON p.page_id = e.page_id
LEFT JOIN campaign_identifier ci
	ON event_time BETWEEN 
		ci.start_date AND ci.end_date
GROUP BY e.visit_id, user_id, campaign_name;
GO

SELECT *
FROM #campaign_analysis;
GO


--Some ideas you might want to investigate further include:

-- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
SELECT 
	CASE
		WHEN impression = 0
			THEN 'not_received'
		ELSE 'received'
	END AS [impression],
	COUNT(user_id) [total_user],
	SUM(page_views) [total_page_views],
	AVG(page_views) [avg_page_views],
	SUM(CASE
		WHEN purchase = 1
			THEN cart_adds
	END) AS [total_cart_added],
	SUM(CASE
		WHEN purchase = 0
			THEN cart_adds
	END) AS [total_abandoned_card_added],
	SUM(purchase) [total_purchase],
	AVG(CASE
		WHEN purchase = 1
			THEN cart_adds
	END) AS [avg_purchased_product]
FROM #campaign_analysis
GROUP BY impression;
GO

-- Does clicking on an impression lead to higher purchase rates?
SELECT 'avg_purchased_product',
	AVG(CASE
		WHEN purchase = 1 AND click = 1 
			THEN cart_adds
	END) AS [clicked_impression],
	AVG(CASE
		WHEN purchase = 1 AND click = 0 AND impression = 1 
			THEN cart_adds
	END) AS [not_clicked_impression]
FROM #campaign_analysis;
GO

/*
Yes, clicking on impression matters and it will lead to higher purchase rate.
Avarage of purchased items when user clicked on impression is higher than items when user haven't clicked on impression.
When clicking on impression, average items purchased is 5. When not clicked, average item is 2
*/

-- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression?
SELECT 'avg_purchased_product',
	AVG(CASE
		WHEN purchase = 1 AND click = 1 
			THEN cart_adds
	END) AS [clicked_impression],
	AVG(CASE
		WHEN purchase = 1 AND impression = 0 
			THEN cart_adds
	END) AS [not_received_impression]
FROM #campaign_analysis;
GO

-- What if we compare them with users who just an impression but do not click?
SELECT 'avg_purchased_product',
	AVG(CASE
		WHEN purchase = 1 AND click = 1 
			THEN cart_adds
	END) AS [clicked_impression],
	AVG(CASE
		WHEN purchase = 1 AND click = 0 AND impression = 1 
			THEN cart_adds
	END) AS [not_clicked_impression],
	AVG(CASE
		WHEN purchase = 1 AND impression = 0
			THEN cart_adds
	END) AS [not_received_impression]
FROM #campaign_analysis;
GO

-- What metrics can you use to quantify the success or failure of each campaign compared to eachother?

/*
I think one of the key metric to measure campaign performance would be look for purchase rate, average purchased product
difference without campaign and with campaign and as we can see from above result while clicked or impression event occured 
purhcase rate tend to get higher compared to users who didn't get ad campaign impression.
*/

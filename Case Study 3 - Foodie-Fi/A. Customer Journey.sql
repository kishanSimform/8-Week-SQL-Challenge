-------------------------
-- A. Customer Journey --
-------------------------

USE [Week 3 - Foodie-Fi];

-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

SELECT customer_id,
	s.plan_id,
	plan_name,
	start_date,
	price
FROM subscriptions s
JOIN plans p
ON s.plan_id = p.plan_id
WHERE customer_id < 9

/*
Customer 1
	He / She joined from 1st Aug 2020 with 'trial' plan, and after a week, 
he / she upgreaded plan from 'trial' to 'basic monthly' from 8th Aug 2020 which cost $9.90 / month.
So he / she has limited access and can only stream their videos.

Customer 2
	He / She joined Foodie-Fi from 20th Sep 2020 with 'trial' plan. After a week
plan automatically upgreaded to 'pro annual' which cost $199 / annual from 27th Sep 2020.
So he / she has no watch time limits and are able to download videos for offline viewing.

Customer 4
	He / She joined Foodie-Fi from 17th Jan 2020 with 'trial' plan. After a week
he / she upgreaded to 'basic monthly' plan which cost $9.90 / month from 24th Jan 2020.
On 21th April 2020, this customer cancelled his / her subscription.
*/
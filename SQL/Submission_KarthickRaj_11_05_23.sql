/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  use new_wheels;/* The Data Dump file has been imported under schema new_wheels*/
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

Select state,count(*) as Number_of_Customers
from customer_t
Group by state
Order by Number_of_Customers DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

CREATE view feedbck as (select quarter_number,customer_feedback,
	CASE
        WHEN customer_feedback = 'Very Bad' THEN 1
        WHEN customer_feedback = 'Bad' THEN 2
        WHEN customer_feedback = 'Okay' THEN 3
        WHEN customer_feedback = 'Good' THEN 4
		WHEN customer_feedback = 'Very Good' THEN 5
        else 'NA'
	END AS feedback_label
from order_t);

Select *
from feedbck;

select quarter_number,TRUNCATE(avg(feedback_label),2) as Average_Quarter
from feedbck
Group by quarter_number
ORDER BY quarter_number DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.*/
 
 select quarter_number,customer_feedback,TRUNCATE((CNT/CNT1)*100,2) as percentage_per_category
from
(select quarter_number,customer_feedback,count(feedback_label) as CNT
from feedbck
Group by quarter_number,feedback_label,customer_feedback
ORDER by quarter_number,feedback_label) as feedbck1 join
(select quarter_number,count(feedback_label) as CNT1
from feedbck
group by quarter_number) as feedbck2 using(quarter_number);


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

select vehicle_maker,count(customer_id) as Count_of_customers
from product_t join order_t using(product_id)
GROUP BY vehicle_maker
ORDER BY Count_of_customers DESC
LIMIT 5;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

select rk.*
from(
select state,vehicle_maker,count(customer_id) as count_of_customers,DENSE_RANK() OVER (PARTITION BY state ORDER BY count(customer_id) DESC) AS Vehicle_RANK
from product_t join order_t using(product_id) join customer_t using(customer_id)
GROUP BY state,vehicle_maker
ORDER BY state,count_of_customers DESC
) as rk
WHERE Vehicle_RANK = 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

select quarter_number,count(order_id) as number_of_orders
from order_t
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
 Select q.*, TRUNCATE(((q.REVENUE - q.PREVIOUS_REVENUE)/q.PREVIOUS_REVENUE)*100,2) as QOQ_Percentage
from
(
select quarter_number,sum(((quantity*vehicle_price))-(quantity*vehicle_price*discount)) as REVENUE,
LAG(sum(((quantity*vehicle_price))-(quantity*vehicle_price*discount))) OVER (ORDER BY quarter_number ASC)  AS PREVIOUS_REVENUE
from order_t
Group by quarter_number
Order by quarter_number DESC) as q;     
      

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

select quarter_number,sum(((quantity*vehicle_price))-(quantity*vehicle_price*discount)) as REVENUE,count(order_id) as Number_of_orders
from order_t
Group by quarter_number
Order by quarter_number ASC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

select credit_card_type,TRUNCATE(avg(discount),2) as Average_of_discount
from customer_t join order_t using(customer_id)
GROUP by credit_card_type
ORDER by 1;



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

select quarter_number,TRUNCATE(avg(datediff(ship_date,order_date)),0) as Average_shipping_time
from order_t
GROUP by quarter_number
ORDER BY 1;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------
/* Total revenue, Total Number od orders*/
select sum(((quantity*vehicle_price))-(quantity*vehicle_price*discount)) as REVENUE,count(order_id) as Number_of_orders
from order_t;
/* Total Customers*/
Select count(*) as Number_of_Customers
from customer_t;
/*Average rating*/
select TRUNCATE(avg(feedback_label),2) as Average_Rating
from feedbck;
/*Average shipping time*/
select TRUNCATE(avg(datediff(ship_date,order_date)),0) as Average_shipping_time
from order_t;
/*% of Good feedback*/
select customer_feedback,TRUNCATE((CNT/(select count(feedback_label) as CNT1
from feedbck))*100,2) as percentage_per_category
from
(select customer_feedback,count(feedback_label) as CNT
from feedbck
Group by feedback_label,customer_feedback
ORDER by feedback_label) as feedbck1;

select TRUNCATE(avg(discount),2) as Average_of_discount
from order_t;
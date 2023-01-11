-- ANALYSIS

USE globalstores;

SELECT *
FROM orders;

-- Total orders by country and with the most sold item by country using co-related query.

SELECT country,COUNT(*) as total_orders,(SELECT TOP 1 product_name FROM orders o1 WHERE o1.country = o.country GROUP BY product_name ORDER BY COUNT(product_name) DESC) as most_sold_item
FROM orders o
GROUP BY country
ORDER BY total_orders DESC;


-- TOP 10 customers with highest order frequency

SELECT TOP 10 customer_name,ROUND(365/CAST(COUNT(customer_name) as float),2) as order_frequency
FROM orders
GROUP BY customer_name
ORDER BY order_frequency DESC;

-- PURCHASE FREQUENCY 

SELECT ROUND(CAST(COUNT(DISTINCT customer_name) as float)/CAST(COUNT(*) as float)*100,2) as purchase_frequency
FROM orders;


-- STORED PROCEDURE to get product information about the no of orders,quantity bought and quantity per order by country taking product name as input

DROP PROCEDURE IF EXISTS product_information
CREATE PROCEDURE product_information
@product_name VARCHAR(255)
AS
SELECT product_name,country,COUNT(product_name) as total_orders,SUM(quantity) as total_quantity_bought,ROUND((SUM(quantity)/CAST(COUNT(product_name) as int)),2) as quantity_per_order
FROM orders
WHERE product_name LIKE '%' + @product_name + '%'
GROUP BY product_name,country
ORDER BY total_orders DESC,quantity_per_order DESC;

exec product_information @product_name = 'Fellowes Lockers, Industrial';


-- late shipping by country

WITH late_shipping as (
SELECT country,order_date,ship_date,DATEDIFF(day,order_date,ship_date) as late_shipping,(SELECT COUNT(*)  FROM orders o1 WHERE o.country = o1.country) as total_orders
FROM orders o
WHERE DATEDIFF(day,order_date,ship_date) > 5
)
SELECT country,COUNT(*) as times_late_shipping,total_orders,FORMAT(CAST(COUNT(*) as decimal(10,2))/CAST(total_orders as decimal(10,2)),'P') as percentage_shipping_delays
FROM late_shipping ls
GROUP BY country,total_orders
ORDER BY times_late_shipping desc


-- TOP 10 REVENUE GENERATING CUSTOMERS 

SELECT TOP 10 customer_name,segment,SUM(sales) as total_sales
FROM orders o
GROUP BY customer_id,customer_name,segment
ORDER BY total_sales DESC;


-- MONTHLY DATE OF ORDERS

SELECT 
CASE WHEN MONTH(order_date) = 1 THEN 'January'
     WHEN MONTH(order_date) = 2 THEN 'February'
	 WHEN MONTH(order_date) = 3 THEN 'March'
	 WHEN MONTH(order_date) = 4 THEN 'April'
	 WHEN MONTH(order_date) = 5 THEN 'May'
	 WHEN MONTH(order_date) = 6 THEN 'June'
	 WHEN MONTH(order_date) = 7 THEN 'July'
	 WHEN MONTH(order_date) = 8 THEN 'August'
	 WHEN MONTH(order_date) = 9 THEN 'September'
	 WHEN MONTH(order_date) = 10 THEN 'October'
	 WHEN MONTH(order_date) = 11 THEN 'November'
     ELSE 'December' END as months,
	 COUNT(*) as total_orders
FROM orders	
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date) ASC;

-- TOP 3 MONTHS BY sales

SELECT TOP 3 DATENAME(month,order_date)as months,COUNT(*) as total_orders
FROM orders
GROUP BY DATENAME(month,order_Date)
ORDER BY total_orders DESC;

-- EDA [ United States ] 


-- NO OF CUSTOMERS IN EACH SEGMENT

SELECT segment,COUNT(segment) as customers
FROM orders
WHERE country LIKE '%United States%'
GROUP BY segment
ORDER BY customers DESC;



-- TOP REVENUE GENERATING SEGMENTS 

SELECT segment,ROUND(SUM(sales),2) as total_sales
FROM orderS
WHERE country LIKE '%United States%'
GROUP BY segment
ORDER BY total_sales DESC;

-- TOP ORDERED SUB-CATEGORIES BY SEGMENT

WITH top_orders_by_segment as (
SELECT segment,sub_category,total_orders,DENSE_RANK() OVER(PARTITION BY segment ORDER BY total_orders DESC) as ranking
FROM (
SELECT segment,sub_category,COUNT(*) as total_orders
FROM orders
WHERE country LIKE '%United States%'
GROUP BY segment,sub_category

) a )
SELECT segment,sub_category,total_orders
FROM top_orders_by_segment
WHERE ranking <= 3;


-- YEAR WISE ORDERS BY SEGMENT

SELECT segment,CAST(DATENAME(year,order_date) as date) as year,COUNT(*) as total_orders
FROM orders
WHERE country LIKE '%United States%'
GROUP BY segment,DATENAME(year,order_date)
ORDER BY segment,DATENAME(year,order_date)ASC

-- Top cities by orders and sales in united states

SELECT top 10 city,COUNT(*) as total_orders,SUM(sales) as total_sales
FROM orders
WHERE country LIKE '%United States%'
GROUP BY city
ORDER BY total_orders DESC,total_sales DESC;



-- YEAR ON YEAR ORDERS GROWTH IN TOP 10 CITIES IN UNITED STATES


WITH year_on_year as (
SELECT o1.city,CAST(DATENAME(year,order_date)as date) as year,CAST(COUNT(*)as float) as total_orders
FROM orders o1
JOIN ( SELECT top 10 city,COUNT(*) as total_orders,SUM(sales) as total_sales
FROM orders
WHERE country LIKE '%United States%'
GROUP BY city
ORDER BY total_orders DESC,total_sales DESC) o2 ON o1.city = o2.city
WHERE country LIKE '%United States%'
GROUP BY o1.city,DATENAME(year,order_date)
)
SELECT city,year,total_orders,CASE
WHEN next_year_orders=0 THEN 0
ELSE round((total_orders/next_year_orders-1)*100,2) END as yoy_growth
FROM ( SELECT city,year,total_orders,COALESCE(CAST(LAG(total_orders) OVER(PARTITION BY city ORDER BY year ASC )as float),0) as next_year_orders FROM year_on_year ) a
ORDER BY city,year
;

-- monthly orders across year BY THE TOP 10 CITITES IN UNITED STATES

SELECT CASE WHEN MONTH(order_date) = 1 THEN 'January'
     WHEN MONTH(order_date) = 2 THEN 'February'
	 WHEN MONTH(order_date) = 3 THEN 'March'
	 WHEN MONTH(order_date) = 4 THEN 'April'
	 WHEN MONTH(order_date) = 5 THEN 'May'
	 WHEN MONTH(order_date) = 6 THEN 'June'
	 WHEN MONTH(order_date) = 7 THEN 'July'
	 WHEN MONTH(order_date) = 8 THEN 'August'
	 WHEN MONTH(order_date) = 9 THEN 'September'
	 WHEN MONTH(order_date) = 10 THEN 'October'
	 WHEN MONTH(order_date) = 11 THEN 'November'
     ELSE 'December' END as months,CAST(DATENAME(year,order_date) as date) as year,COUNT(*) as total_orders
FROM orders o
JOIN ( SELECT top 10 city,COUNT(*) as total_orders,SUM(sales) as total_sales
FROM orders
WHERE country LIKE '%United States%'
GROUP BY city
ORDER BY total_orders DESC,total_sales DESC ) o1 ON o1.city = o.city
WHERE country LIKE '%United States%' 
GROUP BY DATENAME(year,order_date),MONTH(order_date)
ORDER BY DATENAME(year,order_date),MONTH(order_date)

-- NO OF ORDERS BY STATE

SELECT country,COUNT(*) as total_orders
FROM orders

GROUP BY country;


SELECT top 10 city,COUNT(*) as total_orders
FROM orders
WHERE country LIKE '%United States%'
GROUP BY city
ORDER BY total_orders DESC





































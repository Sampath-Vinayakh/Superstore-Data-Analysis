USE superstores_1;

SELECT *
FROM orders;

-- Superstore USA EDA 

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

-- monthly orders BY THE TOP 10 CITITES IN UNITED STATES

SELECT o.city,CASE WHEN MONTH(order_date) = 1 THEN 'January'
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
     ELSE 'December' END as months,COUNT(*) as total_orders
FROM orders o
JOIN ( SELECT top 10 city,COUNT(*) as total_orders,SUM(sales) as total_sales
FROM orders
WHERE country LIKE '%United States%'
GROUP BY city
ORDER BY total_orders DESC,total_sales DESC ) o1 ON o1.city = o.city
WHERE country LIKE '%United States%' 
GROUP BY o.city,MONTH(order_date)
ORDER BY o.city,MONTH(order_date)


-- TOP 10 CITIES BY ORDERS

SELECT top 10 city,COUNT(*) as total_orders
FROM orders
WHERE country LIKE '%United States%' 
GROUP BY city
ORDER BY total_orders DESC


-- AVERAGE ORDER VALUE ACROSS SEGMENTS

SELECT segment,ROUND(total_sales/no_of_orders,2) as average_order_value
FROM (
SELECT COUNT(*) as no_of_orders,SUM(sales) as total_sales,segment
FROM orders
WHERE country LIKE '%United States%' 
GROUP BY segment) a;

-- TOP REVENUE GENERATING SEGMENTS 

SELECT segment,ROUND(SUM(sales),0) as total_sales
FROM orders
WHERE country LIKE '%United States%' 
GROUP BY segment

-- NO OF CUSTOMERS IN EACH SEGMENT

SELECT segment,COUNT(segment) as customers
FROM orders
WHERE country LIKE '%United States%'
GROUP BY segment
ORDER BY customers DESC;



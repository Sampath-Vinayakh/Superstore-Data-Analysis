-- PROJECT QUERIES

USE superstores_1;

-- TO GET CUSTOMERS ACROSS SEGMENT 

SELECT segment,COUNT(segment) as customers
FROM orders
WHERE country LIKE '%United States%'
GROUP BY segment
ORDER BY customers DESC;

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

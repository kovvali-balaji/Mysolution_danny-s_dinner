CREATE SCHEMA dannys_diner;
USE dannys_diner ;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id  INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
SELECT * from members;
SELECT * FROM sales; 
SELECT * FROM menu;


-- -------------CASE STUDY QUESTIONS-------------------------------
-- -1.What is the total amount each customer spent at the restaurant? 
SELECT a.customer_id,SUM(m.price)
FROM sales a 
JOIN menu m ON a.product_id = m.product_id
GROUP BY a.customer_id;  

-- -2.How many days has each customer visited the restaurant?-------------- 
SELECT customer_id,COUNT(DISTINCT order_date) AS no_of_days_visitied
FROM sales 
GROUP BY customer_id;

-- -3.What was the first item from the menu purchased by each customer? 

WITH first_item AS 
	(SELECT s.*,product_name,
    rank() over(partition by s.customer_id ORDER BY s.order_date ) as ranking 
    FROM sales s 
    JOIN menu m 
    ON s.product_id = m.product_id ) 
SELECT * FROM first_item WHERE ranking=1; 

-- -4.What is the most purchased item on the menu and how many times was it purchased by all customers? 
-- 			-----4.1.Most purchesed item------- 
SELECT m.product_id,m.product_name,COUNT(m.product_name) AS no_of_times_purchased
FROM sales s
JOIN menu m  
ON s.product_id = m.product_id
GROUP BY s.product_id,m.product_name
ORDER BY no_of_times_purchased desc
LIMIT 1; 

-- 5.Which item was the most popular for each customer?
with final as(with popular as (
select a.customer_id,b.product_name,count(*) as total
 from sales a
 join menu b
 on a.product_id=b.product_id
 group by a.customer_id,b.product_name)
 
 select customer_id,product_name,total,
 rank() over (partition by customer_id order by total desc) as ranking
 from popular) 
SELECT * from final where ranking =1; 

-- -------6.Which item was purchased first by the customer after they became a member?

	WITH first_item AS (SELECT s.customer_id,mn.product_name,s.order_date,m.join_date,
			rank() over( partition by s.customer_id Order by s.order_date) as ranking
    FROM sales s 
    LEFT JOIN members m 
    ON s.customer_id = m.customer_id
    JOIN menu mn 
    ON s.product_id = mn.product_id
    WHERE s.order_date >= m.join_date) 
    SELECT * from first_item WHERE ranking = 1; 
    
    
-- 7.Which item was purchased just before the customer became a member? 

WITH first_item_before AS (SELECT s.customer_id,mn.product_name,s.order_date,m.join_date,
			rank() over( partition by s.customer_id Order by s.order_date) as ranking
    FROM sales s 
    LEFT JOIN members m 
    ON s.customer_id = m.customer_id
    JOIN menu mn 
    ON s.product_id = mn.product_id
    WHERE s.order_date < m.join_date) 
    SELECT * from first_item_before WHERE ranking = 1;  
    
-- 8.What is the total items and amount spent for each member before they became a member? 

SELECT s.customer_id,COUNT(s.product_id) as total_items , SUM(mn.price)
FROM sales s 
    LEFT JOIN members m 
    ON s.customer_id = m.customer_id
    JOIN menu mn 
    ON s.product_id = mn.product_id
    WHERE s.order_date < m.join_date 
GROUP BY s.customer_id ;
 
 -- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? 
 
WITH total_new_points AS ( SELECT s.customer_id,
		(CASE 
			WHEN m.product_name = 'sushi' then m.price*20 
            ELSE m.price*10
            END ) AS new_points
 FROM sales s 
 JOIN menu m
 ON s.product_id = m.product_id)
 SELECT customer_id,SUM(new_points) from total_new_points GROUP BY customer_id; 

-- --10.In the first week after a customer joins the program (including their join date)
--      they earn 2x points on all items, not just sushi - how many points do customer A and B have 
--      at the end of January?
WITH total_new_points_by_jan AS ( SELECT s.customer_id,
		(CASE 
			WHEN mn.product_name = 'sushi' then mn.price*20 
            WHEN s.order_date BETWEEN m.join_date AND( m.join_date + INTERVAL 6 day)  
            THEN mn.price*20 
            ELSE mn.price*10
            END ) AS new_point
 FROM sales s 
 JOIN menu mn
 ON s.product_id = mn.product_id
 JOIN members m 
 ON s.customer_id = m.customer_id 
 WHERE s.order_date <= '2021-01-31')
 SELECT customer_id,SUM(new_point) from total_new_points_by_jan GROUP BY customer_id; 
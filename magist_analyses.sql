
USE magist;

#In relation to the products:
-- What categories of tech products does Magist have?
SELECT product_category_name
FROM products
WHERE product_category_name IN ('informatica_acessorios','consoles_games','audio','eletronicos', 'pcs', 'pc_gamer', 'tablets_impressao_imagem')
GROUP BY product_category_name;

-- How many products of these tech categories have been sold (within the time window of the database snapshot)? What percentage does that represent from the overall number of products sold?

SELECT  COUNT(pr.product_id), COUNT(oi.order_id), pr.product_category_name
FROM products pr LEFT JOIN order_items oi ON oi.product_id= pr.product_id
WHERE product_category_name IN ('informatica_acessorios','consoles_games','audio','eletronicos','pcs', 'pc_gamer', 'tablets_impressao_imagem')
GROUP BY product_category_name;

SELECT COUNT(product_id) FROM order_items;
# Almost 11 percent


-- What’s the average price of the products being sold?

SELECT AVG(oi.price), o.order_status
FROM order_items oi
LEFT JOIN orders o ON o.order_id=oi.order_id
WHERE order_status="delivered"; 

#WAY1
SELECT products.product_category_name, ROUND(AVG(order_items.price), 2)
FROM order_items
LEFT JOIN products
ON order_items.product_id = products.product_id
WHERE products.product_category_name IN ("audio", "consoles_games", "eletronicos", "informatica_acessorios",
    "pc_gamer", "pcs", "tablets_impressao_imagem")
GROUP BY products.product_category_name;


-- Are expensive tech products popular? *
-- * TIP: Look at the function CASE WHEN to accomplish this task.

SELECT COUNT(*)
FROM (
SELECT products.product_category_name, order_items.price,
    CASE
        WHEN price <= 100 THEN "very cheap"
        WHEN price <= 300 THEN "cheap"
        WHEN price <= 1000 THEN "moderate"
        WHEN price > 1000 THEN "expensive"
        END AS price_category        
FROM order_items
LEFT JOIN products
ON order_items.product_id = products.product_id
WHERE products.product_category_name IN ("audio", "consoles_games", "eletronicos", "informatica_acessorios",
    "pc_gamer", "pcs", "tablets_impressao_imagem")
ORDER BY order_items.price
) AS sales_table
WHERE price_category = "expensive";


SELECT COUNT(*)
FROM order_items
LEFT JOIN products
ON order_items.product_id = products.product_id
WHERE products.product_category_name IN ("audio", "consoles_games", "eletronicos", "informatica_acessorios",
    "pc_gamer", "pcs", "tablets_impressao_imagem") AND price > 1000;

# Almost 1%



#In relation to the sellers:
-- How many sellers are there?
SELECT COUNT(seller_id) as count_seller
FROM sellers;

-- What's the avarage monthly revenue of Magist's seller?

#WAY1
SELECT 
    seller_id, AVG(monthly_rev) AS average
FROM
    (SELECT seller_id,MONTH(shipping_limit_date),
	SUM(price) AS monthly_rev
    FROM order_items
    GROUP BY seller_id , 2) AS monthly
GROUP BY seller_id
ORDER BY AVG(monthly_rev) DESC;
#LIMIT 1000;


#WAY2
SELECT seller_id, ROUND(AVG(total_rev), 2) AS avg_rev
FROM (
SELECT sellers.seller_id, YEAR(order_items.shipping_limit_date) AS year,
MONTH(order_items.shipping_limit_date) AS month, ROUND(SUM(order_items.price), 2) AS total_rev
FROM sellers
LEFT JOIN order_items
ON sellers.seller_id = order_items.seller_id
GROUP BY sellers.seller_id, year, month
ORDER BY year, month
) AS monthly_rev
GROUP BY seller_id
ORDER BY avg_rev DESC;
#LIMIT 1000;


#WAY3
select seller_id, round(avg(price + freight_value), 5) as revenue, month(shipping_limit_date), year(shipping_limit_date)
from order_items
group by  seller_id
order by  shipping_limit_date desc;

-- What’s the average revenue of sellers that sell tech products?

#WAY1
SELECT seller_id, ROUND(AVG(total_rev), 2) AS avg_rev
FROM (
SELECT sellers.seller_id, YEAR(order_items.shipping_limit_date) AS year,
MONTH(order_items.shipping_limit_date) AS month, ROUND(SUM(order_items.price), 2) AS total_rev
FROM sellers
LEFT JOIN order_items
ON sellers.seller_id = order_items.seller_id
LEFT JOIN products
ON order_items.product_id = products.product_id
WHERE products.product_category_name IN ("audio", "consoles_games", "eletronicos", "informatica_acessorios",
"pc_gamer", "pcs", "tablets_impressao_imagem")
GROUP BY sellers.seller_id, year, month
ORDER BY year, month
) AS monthly_rev
GROUP BY seller_id
ORDER BY avg_rev DESC;





# In relation to the delivery time:
-- What’s the average time between the order being placed and the product being delivered? # 12 DAY


#WAY1 Being Delevered 12 Day
SELECT AVG( TIMESTAMPDIFF(DAY, order_purchase_timestamp,
        order_delivered_customer_date )) AS avg_del_day
        FROM orders
        WHERE order_status = "delivered";


#WAY2
SELECT 
    AVG(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS Average_delay_in_days
FROM
    orders;

#WAY3 
SELECT AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_del_time
FROM orders;


-- How many orders are delivered on time vs orders delivered with a delay?
#YUSUF_ARCAN
#On time percentage 93,1
SELECT (89805/96478)*100;

#delay percentage 6,9
SELECT(6665/96478)*100;

#All delivered orders = 96478
SELECT DISTINCT COUNT(order_id) FROM orders
WHERE order_status= "delivered" ;

#On time delivered orders = 89805
#On time percentage 93
SELECT DISTINCT COUNT(order_id) FROM orders
WHERE order_status= "delivered" 
AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 0;

#delivered with delay = 6665
SELECT DISTINCT COUNT(order_id) FROM orders
WHERE order_status= "delivered" 
AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) > 0;

#WAY1
SELECT 
    COUNT(order_id)
FROM
    orders
WHERE
    order_delivered_customer_date <= order_estimated_delivery_date
        AND order_status = 'delivered';
        
#WAY2
SELECT COUNT(*)
FROM orders
WHERE order_status = "delivered"
AND DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date) <= 0;



-- Is there any pattern for delayed orders, e.g. big products being delayed more often?
#WAY1

SELECT seller_id, product_category_name_english, count(product_category_name_english) 

FROM
    orders o
        LEFT JOIN
    order_items ot ON o.order_id = ot.order_id
        LEFT JOIN
    products p ON ot.product_id = p.product_id
        LEFT JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name
WHERE
    order_delivered_customer_date > order_estimated_delivery_date
        AND order_status = 'delivered'
GROUP BY seller_id;

#WAY2
SELECT 
    product_category_name_english,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM
    orders o
        LEFT JOIN
    order_items ot ON o.order_id = ot.order_id
        LEFT JOIN
    products p ON ot.product_id = p.product_id
        LEFT JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name
WHERE
    order_delivered_customer_date > order_estimated_delivery_date
        AND order_status = 'delivered'
ORDER BY (order_delivered_customer_date - order_estimated_delivery_date) DESC;


#WAY2
SELECT product_category_name_english, count(product_category_name_english) 
    #order_delivered_customer_date,
    #order_estimated_delivery_date
FROM
    orders o
        LEFT JOIN
    order_items ot ON o.order_id = ot.order_id
        LEFT JOIN
    products p ON ot.product_id = p.product_id
        LEFT JOIN
    product_category_name_translation pt ON p.product_category_name = pt.product_category_name
WHERE
    order_delivered_customer_date > order_estimated_delivery_date
        AND order_status = 'delivered'
GROUP BY product_category_name_english;




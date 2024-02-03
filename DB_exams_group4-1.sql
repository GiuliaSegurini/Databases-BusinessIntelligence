
-- 1) List firstname, surname and occupation of customers in Burnaby with a 
-- name starting with "M" and finishing with "y"
SELECT fname, lname,occupation  from customer
where city ='Burnaby' and fname LIKE 'M%y' 


--2) List the products bought by only woman customers with a store cost > 2.00

--OSS: da togliere prodotti comprati da uomini, si può togliere comprati da uomini o comprati da uomini con un certo prezzo

--Interpretazione 1
select  sf.product_id  from sales_fact sf 
join customer c on sf.customer_id =c.customer_id 
where c.gender ='F' and sf.store_cost > 2
EXCEPT (
select  sf.product_id  from sales_fact sf 
join customer c on sf.customer_id =c.customer_id 
where c.gender ='M' --and sf.store_cost > 2
)

--Interpretazione 2
select  sf.product_id  from sales_fact sf 
join customer c on sf.customer_id =c.customer_id 
where c.gender ='F' and sf.store_cost > 2
EXCEPT (
select  sf.product_id  from sales_fact sf 
join customer c on sf.customer_id =c.customer_id 
where c.gender ='M' and sf.store_cost > 2
)


--3) List of products (ID and name of the product) bought in 1998 and belonging to the brand "Washington"
-- or "Bravo".
select DISTINCT p.product_id, p.product_name  from sales_fact sf 
join time_by_day tbd on sf.time_id = tbd.time_id 
join product p on sf.product_id =p.product_id 
where tbd.the_year =1998 and (p.brand_name= 'Washington' or p.brand_name= 'Bravo')


-- 4) List the products bought only in 1998

-- con except <> 1998, esclude anche le cose vendute dopo, ma a db non ci sono
select  p.product_id, p.product_name  from sales_fact sf 
join time_by_day tbd on sf.time_id = tbd.time_id 
join product p on sf.product_id =p.product_id 
where tbd.the_year =1998 
except 
(
select  p.product_id, p.product_name  from sales_fact sf 
join time_by_day tbd on sf.time_id = tbd.time_id 
join product p on sf.product_id =p.product_id 
where tbd.the_year <>1998)




--5) List the products (indicating the code and the name) bought with the promotion "Price Winners" and that in 1997 
--have been bought at least once with store sales > 15.00, while in 1998 with store sales > 10.00.
select DISTINCT  p2.product_id, p2.product_name  from sales_fact sf
join promotion p on sf.promotion_id=p.promotion_id 
join time_by_day tbd on sf.time_id =tbd.time_id 
join product p2 on sf.product_id =p2.product_id 
where sf.store_sales >15 and p.promotion_name ='Price Winners' and tbd.the_year =1997
and 
p2.product_id in (

select  sf.product_id  from sales_fact sf 
join time_by_day tbd on sf.time_id =tbd.time_id 
join promotion p on p.promotion_id =sf.promotion_id 
where tbd.the_year =1998 and sf.store_sales >10 and p.promotion_name ='Price Winners')




--6) List customers (indicating the firstname, surname, and number of children) who bought products of the category
--"Fruit" in January 1997 or "Seafood" January 1998.
select DISTINCT  c.fname, c.lname, c.total_children 
from sales_fact sf join customer c
on sf.customer_id =c.customer_id 
join time_by_day tbd on tbd.time_id =sf.time_id 
join product p on sf.product_id =p.product_id 
join product_class pc on p.product_class_id =pc.product_class_id 
where (tbd.the_month='January' and tbd.the_year=1997 and pc.product_category='Fruit') 
or (tbd.the_month='January' and tbd.the_year=1998 and pc.product_category='Seafood')


--7) List store cities with at least 100 active customers in September 1998.
with view_active_customers as(
select DISTINCT sf.customer_id, sf.store_id
from sales_fact sf 
join time_by_day tbd 
on tbd.time_id = sf.time_id 
where tbd.the_month='September'and tbd.the_year=1998)
select s.store_city, count(distinct view_active_customers.customer_id) as total_active_customers
from view_active_customers
join store s 
on s.store_id=view_active_customers.store_id 
group by s.store_city 
having count(distinct view_active_customers.customer_id)>= 100


--8) List for each store country the number of female customers and the number of male customers. Order the result 
--with respect to the store country.
with female_customers as (
select DISTINCT c.customer_id, sf.store_id
from customer c 
join sales_fact sf on c.customer_id=sf.customer_id
where c.gender='F'
),
male_customers as (
select DISTINCT c.customer_id, sf.store_id
from customer c 
join sales_fact sf on c.customer_id=sf.customer_id
where c.gender='M'
)
select s.store_country,count(distinct female_customers.customer_id) as total_female,
count(distinct male_customers.customer_id) as total_male
from store s
left join female_customers on s.store_id=female_customers.store_id
left join male_customers on s.store_id=male_customers.store_id
group by s.store_country 
order by s.store_country 


--9) For each month provide the number of distinct customers who bought at least 10 distinct product categories
with view_categorie_distinte_per_mese as (
select count(distinct pc.product_category) as categorie_distinte_per_mese, tbd.the_month, sf.customer_id 
from sales_fact sf join product p 
on p.product_id =sf.product_id 
join product_class pc  on pc.product_class_id =p.product_class_id 
join time_by_day tbd on tbd.time_id=sf.time_id 
group by tbd.the_month, sf.customer_id  
having count(distinct pc.product_category)>=10)

select view_categorie_distinte_per_mese.the_month, count( view_categorie_distinte_per_mese.customer_id) as total_customer_at_least_10_category
from view_categorie_distinte_per_mese
group by view_categorie_distinte_per_mese.the_month

--10) Given the year 1998, provide for each store and month the average gain with respect to the number of customers 
--and the ration of that value with respect to yearly gain of that store. Thus, assuming that the average gain with 
--respect to the number of customers of a store is the number K and that the yearly gain of that store is T, then the 
--ratio is K/T.
create view sales_98 as
select sf.customer_id, sf.store_id, tbd.the_month, sf.store_sales, sf.store_cost 
from sales_fact sf 
join time_by_day tbd on tbd.time_id =sf.time_id 
where tbd.the_year =1998


with avg_per_store_month as(
---media rispetto ai clienti, per mese e store: totale guadagno/numero dei clienti
select sales_98.the_month, sales_98.store_id,(sum( sales_98.store_sales - sales_98.store_cost))/(count(DISTINCT sales_98.customer_id )) as K
from sales_98
group by sales_98.the_month, sales_98.store_id),
avg_per_store as (
---media rispetto ai clienti, per  store: totale guadagno/numero dei clienti
select sales_98.store_id, (sum( sales_98.store_sales-sales_98.store_cost))/(count(DISTINCT sales_98.customer_id )) as T
from sales_98
group by  sales_98.store_id
)
select  avg_per_store_month.the_month, avg_per_store_month.store_id, avg_per_store_month.K, avg_per_store.T,
(avg_per_store_month.K)/(avg_per_store.T) as ratio
from avg_per_store_month
join avg_per_store on avg_per_store.store_id=avg_per_store_month.store_id





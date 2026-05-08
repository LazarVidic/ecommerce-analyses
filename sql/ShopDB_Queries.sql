/*

 
 In this script we will create couple queries. We will use our data to find informations about our bussines.

 -------------------------------------------------------------------------------------


 Queries
 -------------------------------------------------------------------------------------


1) Find the top 3 customers who have the highest total sales in an east region,
along with their total profit and the number of orders placed.
2) Findtop 3 product subcategories based on the highest number of orders along
with their total sales and total profits.
3) Findthe average product base margin, average profit and average sales by
month where quantity ordered is greater than 10 and sales are greater than
average of sales.
4) Assign rank to each product subcategory by total sales and return top 5
best-selling subcategories.
5) Assign rank to each manager by total profits.
6) Findwhich product subcategory is returned the most times.

 -------------------------------------------------------------------------------------


*/

use ShopDB
go

-- First Query

/*
	1) Find the top 3 customers who have the highest total sales in an east region,
	along with their total profit and the number of orders placed.
*/


select top 3
	c.customer_id,
	c.customer_name,
	count(distinct s.order_id) as CountOfOrders,
	sum(sales) as TotalSales,
	sum(profit) as TotalProfit
from schema_fact.fact_shop s
left join schema_dim.dim_customer c
	on s.customer_id = c.customer_id
left join schema_dim.dim_region r
	on s.region_id = r.region_id
where region = 'East'
group by c.customer_id, customer_name
order by TotalSales desc


-- Second Query

/*
	2) Find top 3 product subcategories based on the highest number of orders along
	with their total sales and total profits.
*/


select top 3 
	product_subcategory, 
	count(order_id) as NumberOfOrders, 
	sum(sales) as TotalSales, 
	sum(profit) as TotalProfit
from schema_fact.fact_shop s 
left join schema_dim.dim_product p
	on s.product_id = p.product_id
group by product_subcategory
order by NumberOfOrders desc


-- Third Query

/*
	3) Find the average product base margin, average profit and average sales by
	   month where quantity ordered is greater than 10 and sales are greater than
	   average of sales.
*/


select 
    datename(month, order_date) AS Months,
    round(avg(product_base_margin), 2) as AvgBaseMargin, 
    round(avg(profit),2) as AvgProfit, 
    round(avg(sales),2) as AvgSales
from schema_fact.fact_shop s
left join schema_dim.dim_product p 
    on s.product_id = p.product_id
where quantity_ordered_new > 10 
	  and sales > (select avg(sales) from schema_fact.fact_shop)
group by
    datename(month, order_date),
    month(order_date)
order by
    month(order_date)



--Better choise if we have dateset with more than 1 year.
/*


select 
	datefromparts(year(order_date), month(order_date), 1) AS date,
	avg(product_base_margin) as AvgBaseMargin, 
	avg(profit) as AvgProfit, 
	avg(sales) AvgSales
from schema_fact.fact_shop s
left join schema_dim.dim_product p 
	on s.product_id = p.product_id
group by
    datefromparts(year(order_date), month(order_date), 1)
order by
    date;


*/

-- Fourth Query

/*
	4) Assign rank to each product subcategory by total sales and return top 5
	best-selling subcategories.
*/


select
	product_subcategory, 
	rank() over (order by round(sum(sales), 2) desc) as BestSellingSubcategory
from schema_fact.fact_shop s 
left join schema_dim.dim_product p 
	on s.product_id = p.product_id
group by product_subcategory



-- Fifth Query

/*
	5) Assign rank to each manager by total profits.
*/


select 
	manager_name, 
	org_region, 
	sum(profit) as TotalProfit,
	rank() over (order by sum(profit) desc) as RankManager
from schema_fact.fact_shop s 
left join schema_dim.dim_organized_region r 
	on s.organized_region_id = r.organized_region_id
left join schema_dim.dim_manager m 
	on r.manager_id = m.manager_id
group by manager_name, org_region
--order by TotalProfit desc


-- Sixth Query

/*
	6) Find which product subcategory is returned the most times.
*/

select top 5
	product_subcategory,
	rank() over (order by count(is_returned) desc) as RankStatus
from schema_fact.fact_shop s 
left join schema_dim.dim_product p 
	on s.product_id = p.product_id
group by product_subcategory




/*
select top 1 
	product_subcategory, 
	count(status) as NumberReturned
from schema_fact.fact_shop s 
left join schema_dim.dim_product p 
	on s.product_id = p.product_id
group by product_subcategory
order by NumberReturned desc
*/

/*


 In this script we will create couple views to present some queries and to be easier to customer to execute and see what's happening with out data,
 also we will use our views for data reporting. 


-------------------------------------------------------------------------------------


Views
-------------------------------------------------------------------------------------


1) Create a view that combines orders from all regions.
2) Create a view that combines previously created orders view with returns and
users.
3) Create a view that shows customer id’s, customer names and their total
discounts, total profits and total sales. Sort table by total sales descending.


-------------------------------------------------------------------------------------

*/

use ShopDB
go

-- 1st View

/*
1) Create a view that combines orders from all regions.
*/


if object_id('vw_orders_by_regions','V') is not null
drop view vw_orders_by_regions

create view vw_orders_by_regions
as
select 
    s.order_priority_id,
    s.organized_region_id,
    o.manager_id,
	s.region_id,
	order_id,
	customer_name,
	order_priority,
	discount,
	unit_price,
	ship_cost,
	product_name,
	product_category,
	product_subcategory,
	product_container,
	region,
	country,
	state_or_province,
	sales,
	profit,
	order_date,
	ship_date
	is_returned
from schema_fact.fact_shop s
left join schema_dim.dim_region r
	on s.region_id = r.region_id
left join schema_dim.dim_order_priority p
	on s.order_priority_id = p.order_priority_id
left join schema_dim.dim_product pr 
	on s.product_id = pr.product_id
left join schema_dim.dim_customer c
	on s.customer_id = c.customer_id
left join schema_dim.dim_organized_region o
	on s.organized_region_id = o.organized_region_id
left join schema_dim.dim_manager m
	on o.manager_id = m.manager_id



select *
from vw_orders_by_regions


-- 2st View

/*
2) Create a view that combines previously created orders view with returns and users.
*/


if object_id('vw_orders_regions_users','V') is not null
drop view vw_orders_regions_users

create view vw_orders_regions_users
as
select 
	o.*,
	manager_name
from vw_orders_by_regions o
left join schema_dim.dim_manager m
	on o.manager_id = m.manager_id



select *
from vw_orders_regions_users


-- 3st View

/*
3) Create a view that shows customer id’s, customer names and their total
discounts, total profits and total sales. Sort table by total sales descending.
*/


if object_id('vw_customer','V') is not null
drop view vw_customer


create view vw_customer
as
select 
	s.customer_id,
	c.customer_name,
	sum(s.discount) as TotalDiscount,
	sum(s.profit) as TotalProfit,
	sum(s.sales) as TotalSales
from schema_fact.fact_shop s
left join schema_dim.dim_customer c
	on s.customer_id = c.customer_id
group by s.customer_id,c.customer_name
/*
order by TotalSales desc
OFFSET 0 ROWS
FETCH NEXT 10000 ROWS ONLY
*/


select *
from vw_customer
order by TotalSales desc





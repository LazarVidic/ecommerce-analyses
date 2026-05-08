----------------------------------------------------

use ShopDB
go

--Check points for PowerBI
----------------------------------------------------


--Page 1 - "Overview"
----------------------------------------------------
select
	count(distinct order_id) as NumOfOrd,
	count(distinct customer_id) as NumOfCust,
	sum(sales) as SumSales,
	sum(profit) as SumProfit

from schema_fact.fact_shop

----------------------------------------------------
select
	count(distinct order_id) as NumOfOrd,
	count(distinct customer_id) as NumOfCust,
	sum(sales) as SumSales,
	sum(profit) as SumProfit,
	product_subcategory

from schema_fact.fact_shop s
left join schema_dim.dim_product p
	on s.product_id = p.product_id
where product_category like '%Technology%'
group by product_subcategory

----------------------------------------------------
select
	count(distinct order_id) as NumOfOrd,
	count(distinct customer_id) as NumOfCust,
	sum(sales) as SumSales,
	sum(profit) as SumProfit
--	product_subcategory

from schema_fact.fact_shop s
left join schema_dim.dim_product p
	on s.product_id = p.product_id
where product_category like '%Furniture%'
--group by product_subcategory



--Page 2 - "Distribution Map"
----------------------------------------------------

select 
 sum(sales) as Sales,
 sum(profit) as Profit,
 region
from schema_fact.fact_shop s
left join schema_dim.dim_region r
	on s.region_id = r.region_id
where state_or_province like '%Texas%'
group by region

----------------------------------------------------

select 
 sum(sales) as Sales,
 sum(profit) as Profit,
 region
from schema_fact.fact_shop s
left join schema_dim.dim_region r
	on s.region_id = r.region_id
where state_or_province like '%Washington%'
group by region

----------------------------------------------------


--Page 3 - "Table"
----------------------------------------------------

select 
	sum(sales) as Sales,
	sum(profit) as Profit


from schema_fact.fact_shop

----------------------------------------------------

select 
	sum(sales) as Sales,
	sum(profit) as Profit

from schema_fact.fact_shop s
left join schema_dim.dim_region r
	on s.region_id = r.region_id
where state_or_province like '%Alabama%'

----------------------------------------------------

select 
	sum(sales) as Sales,
	sum(profit) as Profit

from schema_fact.fact_shop s
left join schema_dim.dim_region r
	on s.region_id = r.region_id
where state_or_province like '%Colorado%'

----------------------------------------------------

select 
	sum(sales) as Sales,
	sum(profit) as Profit

from schema_fact.fact_shop s
left join schema_dim.dim_product p
	on s.product_id = p.product_id
where product_category like '%Furniture%'

----------------------------------------------------

select 
	sum(sales) as Sales,
	sum(profit) as Profit

from schema_fact.fact_shop s
left join schema_dim.dim_order_priority p
	on s.order_priority_id = p.order_priority_id
where order_priority like '%Critical%'

----------------------------------------------------



--Page 4 - "AnalysisSales"
----------------------------------------------------


select 
	city,
	product_category,
	product_subcategory,
	order_priority,
	count(order_id) as CountOfOrders
from schema_fact.fact_shop s 
left join schema_dim.dim_region r
	on s.region_id = r.region_id
left join schema_dim.dim_product p
	on s.product_id = p.product_id
left join schema_dim.dim_order_priority o
	on s.order_priority_id = o.order_priority_id
where product_category like '%Furniture%' and city like 'Los A%'
group by 
	city,
	product_category,
	product_subcategory,
	order_priority

----------------------------------------------------

select 
	city,
	product_category,
	product_subcategory,
	order_priority,
	count(order_id) as CountOfOrders
from schema_fact.fact_shop s 
left join schema_dim.dim_region r
	on s.region_id = r.region_id
left join schema_dim.dim_product p
	on s.product_id = p.product_id
left join schema_dim.dim_order_priority o
	on s.order_priority_id = o.order_priority_id
where state_or_province like '%Florida%' and city like '%Miami%' and product_category like '%Office Supplies%'
group by
	city,
	product_category,
	product_subcategory,
	order_priority


--Page 5 - "DeliveryAnalysis"
----------------------------------------------------


select 
	state_or_province,
	manager_name,
	date
	
from schema_fact.fact_shop s
left join schema_dim.dim_region r
	on s.region_id = r.region_id
left join schema_dim.dim_date d
	on s.order_date = d.date
left join schema_dim.dim_organized_region re
	on s.organized_region_id = re.organized_region_id
left join schema_dim.dim_manager m
	on re.manager_id = m.manager_id
where state_or_province like '%Alabama%'

----------------------------------------------------


select 
	state_or_province,
	date,
	order_priority,
	min(ship_cost) as minShipCost,
	max(ship_cost) as maxShipCost
	
from schema_fact.fact_shop s
left join schema_dim.dim_order_priority op
	on s.order_priority_id = op.order_priority_id
left join schema_dim.dim_region r
	on s.region_id = r.region_id
left join schema_dim.dim_date d
	on s.order_date = d.date
left join schema_dim.dim_organized_region re
	on s.organized_region_id = re.organized_region_id
left join schema_dim.dim_manager m
	on re.manager_id = m.manager_id
where manager_name like '%Erin%' and date between '2015-01-01' and '2015-01-31' and order_priority like '%Low%'
group by 
	state_or_province,
	date,
	order_priority


--Page 6 - "ProfitChange"
----------------------------------------------------

select 
	count(distinct order_id) as UniqueOrders,
	sum(profit) as SumProfit
from schema_fact.fact_shop 

----------------------------------------------------

select 
	count(distinct order_id) as UniqueOrders,
	sum(profit) as SumProfit,
	product_subcategory
from schema_fact.fact_shop s 
left join schema_dim.dim_product p
	on s.product_id = p.product_id
group by product_subcategory
order by UniqueOrders desc

----------------------------------------------------

with temptable as (
select 
	count(distinct order_id) as UniqueOrders,
	sum(profit) as SumProfit,
	product_subcategory
from schema_fact.fact_shop s 
left join schema_dim.dim_product p
	on s.product_id = p.product_id
left join schema_dim.dim_date d
	on s.order_date = d.date
where date between '2015-04-01' and '2015-04-30' and product_category like '%Furniture%'
group by product_subcategory
--order by UniqueOrders desc
) 
select 
	sum(UniqueOrders) as Orders,
	sum(SumProfit) as TotalProfit
from temptable

----------------------------------------------------

select 
	count(distinct order_id) as UniqueOrders,
	sum(profit) as SumProfit,
	product_subcategory
from schema_fact.fact_shop s 
left join schema_dim.dim_product p
	on s.product_id = p.product_id
left join schema_dim.dim_date d
	on s.order_date = d.date
where date between '2015-04-30' and '2015-06-01' and product_category like '%Office Supplies%'
group by product_subcategory
order by UniqueOrders desc

----------------------------------------------------

select 
	count(distinct order_id) as UniqueOrders,
	sum(profit) as SumProfit,
	product_subcategory
from schema_fact.fact_shop s 
left join schema_dim.dim_product p
	on s.product_id = p.product_id
left join schema_dim.dim_region r
	on s.region_id = r.region_id
where state_or_province like '%California%'
group by product_subcategory
order by UniqueOrders desc



select *
from schema_fact.fact_shop


--Page 7 - "CustomerAnalysis"
----------------------------------------------------

select
	sum(sales) as AvgSales,
	product_name,
	order_date,
	ship_date
from schema_fact.fact_shop s
left join schema_dim.dim_customer c
	on s.customer_id = c.customer_id
left join schema_dim.dim_product p
	on s.product_id = p.product_id
where customer_name like '%Aaron Dillon%'
group by 
	product_name,
	order_date,
	ship_date

----------------------------------------------------

select
	sum(sales) as AvgSales,
	product_name,
	order_date,
	ship_date
from schema_fact.fact_shop s
left join schema_dim.dim_customer c
	on s.customer_id = c.customer_id
left join schema_dim.dim_product p
	on s.product_id = p.product_id
left join schema_dim.dim_region r
	on s.region_id = r.region_id
where postal_code = '01540'
group by 
	product_name,
	order_date,
	ship_date


--Page 8 - "CumulativeOrders"
----------------------------------------------------


select 
	count(distinct order_id) as JanFeb
from schema_fact.fact_shop
where order_date between '2015-01-01' and '2015-03-01'

----------------------------------------------------

select 
	count(distinct order_id) as JanFeb
from schema_fact.fact_shop
where order_date between '2015-01-01' and '2015-01-31'


select 
	order_date
from schema_fact.fact_shop


--Page 9 - "DiffAnalysis"
----------------------------------------------------


select 
    order_date,
    SUM(sales) AS total_sales
from schema_fact.fact_shop
where order_date in ('2015-01-14', '2015-01-15')
group by order_date
order by order_date;

----------------------------------------------------

select 
    order_date,
    SUM(sales) AS total_sales
from schema_fact.fact_shop
where order_date between '2015-01-01' and '2015-02-01'
group by order_date
order by order_date asc;


--Page 10 - "OrderAnalysis"
----------------------------------------------------

with TotalSales as (
select 
	sum(sales) as TotalSales,
	count(distinct order_id) as CountOrder
from schema_fact.fact_shop
where order_date = '2015-06-07'
)
select
	TotalSales / CountOrder as AverageOrderPrice
from TotalSales


----------------------------------------------------

with TotalSales2 as (
select 
	sum(sales) as TotalSales,
	count(distinct order_id) as CountOrder
from schema_fact.fact_shop
where order_date = '2015-05-05'
)
select
	TotalSales / CountOrder as AverageOrderPrice
from TotalSales2

-----------------------------------------------------

select 
	count(order_id) as CountofOrders,
	product_category
from schema_fact.fact_shop s
left join schema_dim.dim_product p
	on s.product_id = p.product_id
where order_date between '2015-05-01' and '2015-05-31'
group by product_category

-----------------------------------------------------



















-- Check point for Python
-----------------------------------------------------


select top 10
	c.customer_name,
	sum(sales) as Sales
from schema_fact.fact_shop s
left join schema_dim.dim_customer c
	on s.customer_id = c.customer_id
group by c.customer_name
order by sum(sales) desc



select 
	customer_name,
	c.customer_id,
	sum(sales) as Sales
from schema_fact.fact_shop s
left join schema_dim.dim_customer c
	on s.customer_id = c.customer_id
where c.customer_name = 'Kristine Connolly'
group by  customer_name, c.customer_id
order by sum(sales) desc



-- Python check(pivot table)


--Pivot table 1: Pivot table by Order Priority
-----------------------------------------------------

select 
	order_priority,
	avg(discount) as AvgDis,
	sum(profit) as AvgProfit,
	sum(sales) as AvgSales,
	avg(ship_cost) as AvgShipCost
from schema_fact.fact_shop s
left join schema_dim.dim_order_priority o
on s.order_priority_id = o.order_priority_id
group by order_priority 
order by order_priority 

-----------------------------------------------------

--Pivot table 2: Pivot table by Customer Segment

select 
	customer_segment,
	avg(discount) as AvgDis,
	sum(profit) as AvgProfit,
	sum(sales) as AvgSales,
	avg(ship_cost) as AvgShipCost
from schema_fact.fact_shop s
left join schema_dim.dim_customer d
on s.customer_id = d.customer_id
group by customer_segment 
order by customer_segment

-----------------------------------------------------

--Pivot table 3: Pivot table by Product Category

select 
	product_category,
	avg(discount) as AvgDis,
	sum(profit) as AvgProfit,
	sum(sales) as AvgSales,
	avg(ship_cost) as AvgShipCost
from schema_fact.fact_shop s
left join schema_dim.dim_product p
on s.product_id = p.product_id
group by product_category 
order by product_category

-----------------------------------------------------

--Pivot table 4: Pivot table by Product Subcategory

select 
	product_subcategory,
	avg(discount) as AvgDis,
	sum(profit) as AvgProfit,
	sum(sales) as AvgSales,
	avg(ship_cost) as AvgShipCost
from schema_fact.fact_shop s
left join schema_dim.dim_product p
on s.product_id = p.product_id
group by product_subcategory 
order by product_subcategory

-----------------------------------------------------

--Pivot table 5: Pivot table by State or Province

select 
	state_or_province,
	avg(discount) as AvgDis,
	sum(profit) as AvgProfit,
	sum(sales) as AvgSales,
	avg(ship_cost) as AvgShipCost
from schema_fact.fact_shop s
left join schema_dim.dim_region p
on s.region_id = p.region_id
group by state_or_province 
order by state_or_province




--Scatter plot check
-----------------------------------------------------

select
count(distinct order_id),
product_subcategory
from schema_fact.fact_shop s
left join schema_dim.dim_product p
on s.product_id = p.product_id
group by product_subcategory
order by product_subcategory desc


select top 100
sales
from schema_fact.fact_shop s
left join schema_dim.dim_product p
on s.product_id = p.product_id
where product_category = 'Furniture'
order by sales desc


-----------------------------------------------------

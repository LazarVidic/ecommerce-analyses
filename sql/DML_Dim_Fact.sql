-- DML script
-- Insert "ShopDB" script 
/*

	Purpose: Create a script to insert data to database ShopDB including inserting data to tables stage, dimensions and fact table.
 
*/

use ShopDB
go

--Insert into schemas for our datewarehouse
/*

1. Schema stage

	This schema_stage includes 3 tables for bulk inserts. 
-------------------------------------------------------------------------------------------

	Table 1 is for bulk insert 'staging_sales' and it will include 4 csv files about all sales.
	Table 2 is for bulk insert 'staging_returns' and it will include 1 csv file about returns and status of returns.
	Table 3 is for bulk insert 'staging_users' and it will include 1 csv file about managers.


2. Schema dimension

	This schema_dim includes 7 tables for insert data in dimension tables. 
-------------------------------------------------------------------------------------------

	In tables in this schema we will use stage schema to insert data from schema_stage into tables in schema_dim.
	


3. Schema fact

	This schema_fact includes 1 table for insert data into fact table. 
-------------------------------------------------------------------------------------------

	In fact table in this schema we will use stage schema to insert data from schema_stage into table in schema_fact.


 
*/

------------------------------------------------------------------------------------------


--Insert into SCHEMA DIM(schema_dim)


--Insert into dim Order Priority
Insert into schema_dim.dim_order_priority(order_priority)
select distinct 
    trim(order_priority)
from schema_stage.staging_order


--Insert into dim Ship Mode
Insert into schema_dim.dim_ship_mode(ship_mode)
select distinct 
    trim(ship_mode)
from schema_stage.staging_order


--Insert into dim Product
Insert into schema_dim.dim_product(product_category,product_subcategory,product_container,product_name,product_base_margin)
select distinct 
    trim(product_category),
    trim(product_sub_category),
    trim(product_container),
    trim(product_name),
    product_base_margin
from schema_stage.staging_order


--Insert into dim Customer
Insert into schema_dim.dim_customer(customer_key,customer_name,customer_segment)
select distinct 
    customer_id,
    trim(customer_name),
    trim(customer_segment)
from schema_stage.staging_order


--select *
--from schema_dim.dim_date


--Insert into dim Date
declare @datum Date

set @datum = cast('2015-01-01' as Date)

while @datum <= cast('2015-12-31' as Date)
begin 
    insert into schema_dim.dim_date
    values(@datum)
    set @datum = dateadd(day,1,@datum)
end


--Insert into dim Region
Insert into schema_dim.dim_region(country,region,state_or_province,city,postal_code)
select distinct 
    trim(country),
    trim(region),
    trim(state_or_province),
    trim(city),
    format(postal_code,'00000') as postal_code
from schema_stage.staging_order


--Insert into dim Manager
Insert into schema_dim.dim_manager(manager_name)
select distinct 
    trim(manager)
from schema_stage.staging_user 


--Insert into dim Organized Region
Insert into schema_dim.dim_organized_region(org_region,manager_id)
select distinct 
    trim(region), 
    manager_id
from schema_stage.staging_user u 
left join schema_dim.dim_manager m on u.manager = m.manager_name



------------------------------------------------------------

--Insert into SCHEMA FACT(schema_fact)

insert into schema_fact.fact_shop(order_id,product_id,ship_mode_id,order_priority_id,customer_id,organized_region_id,region_id,
                                  profit,sales,ship_date,is_returned,unit_price,order_date,ship_cost,discount,quantity_ordered_new)
select distinct
                o.order_id,
                p.product_id,
                sm.ship_mode_id,
                op.order_priority_id,
                c.customer_id,
                orr.organized_region_id,
                re.region_id,
                profit,
                sales,
                ship_date,
                case status
                when 'Returned' then 1 
                else 0
                end as IsReturned,
                unit_price,
                order_date,
                shipping_cost,
                case when discount is null then 0 
                else discount end,
                case when quantity_ordered_new is null then 0
                else quantity_ordered_new end

from schema_stage.staging_order o 
left join schema_stage.staging_return r on o.order_id = r.order_id
join schema_dim.dim_order_priority op on o.order_priority = op.order_priority  
join schema_dim.dim_ship_mode sm on o.ship_mode = sm.ship_mode
join (
    select *,
           row_number() over(
               partition by product_name, product_category, product_subcategory, product_container
               order by product_id
           ) as rn
    from schema_dim.dim_product
) p 
    on o.product_name = p.product_name
   and o.product_category = p.product_category
   and o.product_sub_category = p.product_subcategory
   and o.product_container = p.product_container
   and p.rn = 1
join (
    select *,
           row_number() over(
               partition by customer_key, customer_name, customer_segment
               order by customer_id
           ) as rn
    from schema_dim.dim_customer
) c
    on o.customer_id = c.customer_key
   and o.customer_name = c.customer_name
   and o.customer_segment = c.customer_segment
   and c.rn = 1
join schema_dim.dim_organized_region orr on o.region = orr.org_region
join schema_dim.dim_date d on o.order_date = d.date
join schema_dim.dim_region re on o.postal_code = re.postal_code
        and o.city = re.city
        and o.country = re.country
        and o.region = re.region
        and o.state_or_province = re.state_or_province





---------------------------------------------------------------------------------------


/*
select 
count(*)
from schema_fact.fact_shop

select 
count(*)
from schema_dim.dim_order_priority
*/


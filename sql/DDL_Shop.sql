-- DDL script
-- Create "ShopDB" script 
/*

	Purpose: Creating automatization script for ShopDB database including creating schemas, tables dimensions and fact table.
 
*/

--use ShopDB
--go

--Create schemas for our datewarehouse
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


/*

SELECT  *
FROM sys.schemas 

*/

--SCHEMA DDL
----------------------------------------------------------------------------------------


--Check does schema 'schema_stage' exsists and then drop it 


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'schema_stage')
EXEC('CREATE SCHEMA schema_stage'); 


--drop schema [if exists] schema_stage 

--Check does schema 'schema_dim' exsists and then drop it 


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'schema_dim')
EXEC('CREATE SCHEMA schema_dim'); 

--drop schema [if exsists] schema_dim 


--Check does schema 'schema_fact' exsist and then drop it 


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'schema_fact')
EXEC('CREATE SCHEMA schema_fact'); 


--drop schema [if exsists] schema_fact 
----------------------------------------------------------------------------------------

--Check does table 'staging_order' exsist and then drop it 
IF OBJECT_ID('schema_stage.staging_order', 'U') IS NOT NULL 
drop table schema_stage.staging_order 
go


--Check does table 'staging_returns' exsist and then drop it 
IF OBJECT_ID('schema_stage.staging_return', 'U') IS NOT NULL 
drop table schema_stage.staging_return
go


--Check does table 'staging_user' exsist and then drop it 
IF OBJECT_ID('schema_stage.staging_user', 'U') IS NOT NULL 
drop table schema_stage.staging_user
go


--Check does table 'schema_fact.fact_shop' exsist and then drop it 
IF OBJECT_ID('schema_fact.fact_shop', 'U') IS NOT NULL 
drop table schema_fact.fact_shop 
go


--Check does table 'schema_dim.dim_organized_region ' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_organized_region', 'U') IS NOT NULL 
drop table schema_dim.dim_organized_region
go


--Check does table 'schema_dim.dim_manager ' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_manager', 'U') IS NOT NULL 
drop table schema_dim.dim_manager
go


--Check does table 'schema_dim.dim_product' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_product', 'U') IS NOT NULL 
drop table schema_dim.dim_product
go


--Check does table 'dim_ship_mode' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_ship_mode', 'U') IS NOT NULL 
drop table  schema_dim.dim_ship_mode 
go


--Check does table 'schema_dim.dim_order_priority' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_order_priority', 'U') IS NOT NULL 
drop table schema_dim.dim_order_priority
go


--Check does table 'schema_dim.dim_customer ' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_customer', 'U') IS NOT NULL 
drop table schema_dim.dim_customer
go


--Check does table 'schema_dim.dim_date ' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_date', 'U') IS NOT NULL 
drop table schema_dim.dim_date
go


--Check does table 'schema_dim.dim_region ' exsist and then drop it 
IF OBJECT_ID('schema_dim.dim_region', 'U') IS NOT NULL 
drop table schema_dim.dim_region
go



--TABLES DDL
----------------------------------------------------------------------------------------

--Create tables for schema_stage


--Create table schema_stage.staging_order 
create table schema_stage.staging_order 
(
	row_id int,
	order_priority nvarchar(30),
	discount decimal(10,2),
	unit_price decimal(10,2),
	shipping_cost decimal(10,2),
	customer_id int,
	customer_name nvarchar(50),
	ship_mode nvarchar(30),
	customer_segment nvarchar(30),
	product_category nvarchar(30),
	product_sub_category nvarchar(100),
	product_container nvarchar(20),
	product_name nvarchar(100),
	product_base_margin decimal(10,2),
	country nvarchar(30),
	region nvarchar(20),
	state_or_province nvarchar(30),
	city nvarchar(30),
	postal_code int,
	order_date date,
	ship_date date,
	profit decimal(10,2),
	quantity_ordered_new int,
	sales decimal(10,2),
	order_id int


);
go

--Create table schema_stage.staging_order 
create table schema_stage.staging_return 
(
	order_id int,
	status nvarchar(20)


);
go

--Create table schema_stage.staging_order 
create table schema_stage.staging_user 
(
	region nvarchar(30),
	manager nvarchar(10)

)


------------------------------------------------------------------------------------------

--SCHEMA DIM (schema_dim)


--Create Dimension Order Priority
create table schema_dim.dim_order_priority 
(
	order_priority_id int identity(1,1) primary key,
	order_priority nvarchar(30)


);

--Create Dimension Ship Mode
create table schema_dim.dim_ship_mode 
(

	ship_mode_id int identity(1,1) primary key,
	ship_mode nvarchar(30)


);

--Create Dimension Product
create table schema_dim.dim_product 
(
	product_id int identity(1,1) primary key,
	product_category nvarchar(30),
	product_subcategory nvarchar(50),
	product_container nvarchar(30),
	product_name nvarchar(100),
	product_base_margin float


);

--Create Dimension Customer
create table schema_dim.dim_customer
(
	customer_id int identity(1,1) primary key,
	customer_key int,
	customer_name nvarchar(50),
	customer_segment nvarchar(50)


);

--Create Dimension Date
create table schema_dim.dim_date
(
	date date primary key


);

--Create Dimension Manager
create table schema_dim.dim_manager 
(

	manager_id int identity(1,1) primary key,
	manager_name nvarchar(30)


);

--Create Dimension Region
create table schema_dim.dim_organized_region 
(
	organized_region_id int identity(1,1) primary key,
	org_region nvarchar(30), 
	manager_id int,
	-- fk manager
    	CONSTRAINT FK_dim_organized_region_dim_manager
        	FOREIGN KEY (manager_id)
        	REFERENCES schema_dim.dim_manager(manager_id)


);

--Create Dimension Region
create table schema_dim.dim_region 
(
	region_id int identity(1,1) primary key,
	country nvarchar(30),
	region nvarchar(30),
	state_or_province nvarchar(30),
	city nvarchar(30),
	postal_code nvarchar(10)


);


-----------------------------------------------------------------------------------

--SCHEMA FACT(schema_fact)


--Create Fact Shop
create table schema_fact.fact_shop 
(
	shop_id int identity(1,1) primary key,
	order_id int,
	product_id int,
	ship_mode_id int,
	order_priority_id int,
	customer_id int,
	organized_region_id int,
	region_id int,
	profit decimal(10,2),
	sales decimal(10,2),
	ship_date date,
	is_returned nvarchar(10),
	unit_price decimal(10,2),
	order_date date,
	ship_cost decimal(10,2),
	discount decimal(10,2),
	quantity_ordered_new int,

	-- fk order priority
    	CONSTRAINT FK_fact_shop_dim_order_priority
        	FOREIGN KEY (order_priority_id)
        	REFERENCES schema_dim.dim_order_priority(order_priority_id),
	-- fk ship mode
    	CONSTRAINT FK_fact_shop_dim_ship_mode
        	FOREIGN KEY (ship_mode_id)
        	REFERENCES schema_dim.dim_ship_mode(ship_mode_id),
 	-- fk product
    	CONSTRAINT FK_fact_shop_dim_product
        	FOREIGN KEY (product_id)
        	REFERENCES schema_dim.dim_product(product_id),
	-- fk customer
    	CONSTRAINT FK_fact_shop_dim_customer
        	FOREIGN KEY (customer_id)
        	REFERENCES schema_dim.dim_customer(customer_id),
	-- fk organized region
    	CONSTRAINT FK_fact_shop_dim_organized_region
        	FOREIGN KEY (organized_region_id)
        	REFERENCES schema_dim.dim_organized_region(organized_region_id),
	-- fk region
    	CONSTRAINT FK_fact_shop_dim_region
        	FOREIGN KEY (region_id)
        	REFERENCES schema_dim.dim_region(region_id),
	-- fk date
    	CONSTRAINT FK_fact_shop_dim_date
        	FOREIGN KEY (order_date)
        	REFERENCES schema_dim.dim_date(date)


);


/*
SELECT * 
FROM sys.tables 
WHERE name = 'dim_date';
*/



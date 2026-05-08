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


--Insert into staging_order


--Insert Orders_Central into table staging_order 
BULK INSERT schema_stage.staging_order
FROM 'C:\Users\lazar.vidic\Desktop\Internship_Data\Internship\Orders_Central.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
go


--select * 
--from schema_stage.staging_order


--Insert Orders_East into table staging_order 
BULK INSERT schema_stage.staging_order
FROM 'C:\Users\lazar.vidic\Desktop\Internship_Data\Internship\Orders_East.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
go


--Insert Orders_South into table staging_order 
BULK INSERT schema_stage.staging_order
FROM 'C:\Users\lazar.vidic\Desktop\Internship_Data\Internship\Orders_South.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
go


--Insert Order_West into table staging_order 
BULK INSERT schema_stage.staging_order
FROM 'C:\Users\lazar.vidic\Desktop\Internship_Data\Internship\Orders_West.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
go


----------------------------------------------------------------------------------------

--Insert into staging_return

BULK INSERT schema_stage.staging_return
FROM 'C:\Users\lazar.vidic\Desktop\Internship_Data\Internship\Returns.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
go


--Insert into staging_user

BULK INSERT schema_stage.staging_user
FROM 'C:\Users\lazar.vidic\Desktop\Internship_Data\Internship\Users.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = '|',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
go

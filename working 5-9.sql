USE GREEN_THUMB
GO

-- extra product types are needed
INSERT INTO tblProductType (ProductTypeName, ProductTypeDesc)
	VALUES('Compost & Rainbarrel', 'Various compost and rainbarrel products')

INSERT INTO tblProductType (ProductTypeName, ProductTypeDesc)
	VALUES('Watering Products', 'Products to water your plants')
	
INSERT INTO tblProductType (ProductTypeName, ProductTypeDesc)
	VALUES('Hydroponics', 'For all your soilless gardening needs')
	
INSERT INTO tblProductType (ProductTypeName, ProductTypeDesc)
	VALUES('Greenhouse', 'Greenhouse gear')

-- make the tables
CREATE TABLE WORKING_Details
	(DetailID INT IDENTITY(1,1) PRIMARY KEY,
	DetailType [varchar](999) NULL,
	[Detail] [varchar](999) NULL,
	[source_JobURL] [varchar](999) NULL)
GO

CREATE TABLE WORKING_Products
	(ProductID INT IDENTITY(1,1) PRIMARY KEY,
	ProductName VARCHAR(999),
	ProductTypeID INT,
	ProductDesc VARCHAR(999),
	Price VARCHAR(100))
GO

-- insert into working products
INSERT INTO WORKING_Products (ProductName, ProductDesc, Price)
SELECT product_title, JobURL, price
FROM raw_compost_and_rainbarrel_products

UPDATE WORKING_Products 
SET ProductTypeID = 14
WHERE ProductTypeID IS NULL

INSERT INTO WORKING_Products (ProductName, ProductDesc, Price)
SELECT product_title, JobURL, price
FROM RAW_gardening_tools_products

UPDATE WORKING_Products 
SET ProductTypeID = 8
WHERE ProductTypeID IS NULL

INSERT INTO WORKING_Products (ProductName, ProductDesc, Price)
SELECT product_title, JobURL, price
FROM Raw_Watering_Products

UPDATE WORKING_Products 
SET ProductTypeID = 15
WHERE ProductTypeID IS NULL

INSERT INTO WORKING_Products (ProductName, ProductDesc, Price)
SELECT product_title, JobURL, price
FROM RAW_seeds_products

UPDATE WORKING_Products 
SET ProductTypeID = 11
WHERE ProductTypeID IS NULL

INSERT INTO WORKING_Products (ProductName, ProductDesc, Price)
SELECT product_title, JobURL, price
FROM RAW_hydroponics_products

UPDATE WORKING_Products 
SET ProductTypeID = 16
WHERE ProductTypeID IS NULL

INSERT INTO WORKING_Products (ProductName, ProductDesc, Price)
SELECT product_title, JobURL, price
FROM RAW_pots_and_planters_products_with_url

UPDATE WORKING_Products 
SET ProductTypeID = 10
WHERE ProductTypeID IS NULL

INSERT INTO WORKING_Products (ProductName, ProductDesc, Price)
SELECT product_title, JobURL, price
FROM RAW_greenhouse_products

UPDATE WORKING_Products 
SET ProductTypeID = 17
WHERE ProductTypeID IS NULL

-- insert into working details
INSERT INTO WORKING_Details (Detail, DetailType, source_JobURL)
SELECT DetailType, DetailValue, source_JobURL
FROM random_gardening_tools_details

INSERT INTO WORKING_Details (Detail, DetailType, source_JobURL)
SELECT DetailType, DetailValue, source_JobURL
FROM new_random_pots_and_planters_details

INSERT INTO WORKING_Details (Detail, DetailType, source_JobURL)
SELECT DetailType, DetailValue, source_JobURL
FROM Mixed_Product_Details

-- some fields were blank
DELETE FROM WORKING_Details
WHERE Detail = '' OR DetailType = ''

-- insert into detailType and update workingDetail to corresponding FK
INSERT INTO tblDetailType (DetailTypeName)
SELECT DISTINCT DetailType
FROM WORKING_Details

UPDATE WORKING_Details
SET DetailType = DetailTypeID
FROM WORKING_Details WD
	JOIN tblDetailType DT ON WD.DetailType = DT.DetailTypeName




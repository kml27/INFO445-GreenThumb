/*EC Team Project*/

USE GREEN_THUMB

/*CASE STATEMENT WORK & Stored Procedures
No other related codes. 
We have over 15,000 rows (associated table may be more over 20,000) in the customers.
Other tables may have references: CustomerType, ProductType, CustCustType, etc.
*/

/*
-- Emily Ding
CASE: label customers' address based on the 7 regions where our customers come from:
1) New England Region: Maine, Rhode Island, Vermont, Connecticut, New Hampshire and Massachusetts
2) Mid-Atlantic Region: New York, New Jersey and Pennsylvania
3) Southern Region: Virginia, West Virginia, Kentucky, Delaware, Maryland, North 
				and South Carolina, Tennessee, Arkansas, Louisiana, Florida, Georgia, 
				Alabama and Mississipp
4) Mid-West Region: Michigan, North and South Dakota, Iowa, Minnesota, Kansas, Nebraska, 
				Ohio, Indiana, Illinois, Wisconsin and Missouri
5) South-West Region: Texas, Arizona, New Mexico and Oklahoma
6) Pacific Coastal Region: California, Oregon and Washington
7) Rocky Mountains: else, Montana, Idaho, Colorado, Utah, Wyoming and Nevada
*/

SELECT (CASE
		WHEN [State] IN ('Maine, ME', 'Rhode Island, RI', 'Vermont, VT', 'Connecticut, CT', 
		'New Hampshire, NH', 'Massachusetts, MA') 
		THEN 'New England Region'
		WHEN [State] IN ('New York, NY', 'New Jersey, NJ', 'Pennsylvania, PA') 
		THEN 'Mid-Atlantic Region'
		WHEN [State] IN ('Virginia, VA', 'West Virginia, WV', 'Kentucky, KY', 'Delaware, DE',
		'Maryland, MD', 'North Carolina, NC', 'South Carolina, SC', 'Tennessee, TN', 
		'Arkansas, AR, ', 'Louisiana, LA', 'Florida, FL', 'Georgia, GA', 'Alabama, AL', 
		'Mississipp, MS') 
		THEN 'Southern Region'
		WHEN [State] IN ('Michigan, MI', 'North Dakota, ND', 'South Dakota, SD', 'Iowa, IA', 
		'Minnesota, MN', 'Kansas,KS', 'Nebraska, NE', 'Ohio, OH', 'Indiana, IN', 'Illinois, IL', 
		'Wisconsin, WI', 'Missouri, MO') 
		THEN 'Mid-West Region'
		WHEN [State] IN ('Texas, TX', 'Arizona, AZ', 'New Mexico, NM', 'Oklahoma, OK')
		THEN 'South-West Region'
		WHEN [State] IN ('California, CA', 'Oregon, OR', 'Washington, WA')
		THEN 'Pacific Coastal Region'
		ELSE 'Rocky Mountains'
		END) AS 'Customer_Region', COUNT(*) AS 'TotalNum'
FROM tblCustomer C JOIN tblAddress A ON C.AddressID = A.AddressID
GROUP BY (CASE
		WHEN [State] IN ('Maine, ME', 'Rhode Island, RI', 'Vermont, VT', 'Connecticut, CT', 
		'New Hampshire, NH', 'Massachusetts, MA') 
		THEN 'New England Region'
		WHEN [State] IN ('New York, NY', 'New Jersey, NJ', 'Pennsylvania, PA') 
		THEN 'Mid-Atlantic Region'
		WHEN [State] IN ('Virginia, VA', 'West Virginia, WV', 'Kentucky, KY', 'Delaware, DE',
		'Maryland, MD', 'North Carolina, NC', 'South Carolina, SC', 'Tennessee, TN', 
		'Arkansas, AR, ', 'Louisiana, LA', 'Florida, FL', 'Georgia, GA', 'Alabama, AL', 
		'Mississipp, MS') 
		THEN 'Southern Region'
		WHEN [State] IN ('Michigan, MI', 'North Dakota, ND', 'South Dakota, SD', 'Iowa, IA', 
		'Minnesota, MN', 'Kansas,KS', 'Nebraska, NE', 'Ohio, OH', 'Indiana, IN', 'Illinois, IL', 
		'Wisconsin, WI', 'Missouri, MO') 
		THEN 'Mid-West Region'
		WHEN [State] IN ('Texas, TX', 'Arizona, AZ', 'New Mexico, NM', 'Oklahoma, OK')
		THEN 'South-West Region'
		WHEN [State] IN ('California, CA', 'Oregon, OR', 'Washington, WA')
		THEN 'Pacific Coastal Region'
		ELSE 'Rocky Mountains'
		END)
ORDER BY TotalNum DESC

/*Working for Customer table, Product table, inserts datas, and populate data for Store Proc
*/

CREATE TABLE [dbo].[WorkingCustomerData](
	[CustomerID] int identity (1,1) primary key not null,
	[CustomerFname] [varchar](50) NULL,
	[CustomerLname] [varchar](50) NULL,
	[CustomerAddress] [varchar](100) NULL,
	[CustomerCity] [varchar](50) NULL,
	[CustomerState] [varchar](50) NULL,
	[CustomerZIP] int NULL,
	[Email] [varchar](100) NULL,
	[DateOfBirth] date NULL,
	[PhoneNum] varchar (20) NULL,
)

INSERT INTO [WorkingCustomerData] (
[CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum])
SELECT [CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum]
FROM [RAW_CUSTOMER]

INSERT INTO [dbo].[tblProductType] ([ProductTypeName], [ProductTypeDesc])
SELECT [ProductTypeName], [ProductTypeDescr]
FROM [dbo].[RAW_PRODUCT_TYPE]

SET IDENTITY_INSERT tblAddress ON;
INSERT INTO tblAddress (AddressID, StreetAddress, City, [State], Zip) SELECT CustomerID, CustomerAddress, CustomerCity, CustomerState, CustomerZIP FROM WorkingCustomerData;
SET IDENTITY_INSERT tblAddress OFF;
SET IDENTITY_INSERT tblCustomer ON;
INSERT INTO tblCustomer (CustomerID, FirstName, LastName, Email, PhoneNumber, DOB, AddressID) SELECT CustomerID, CustomerFName, CustomerLName, Email, PhoneNum, DateOfBirth, CustomerID FROM WorkingCustomerData;
SET IDENTITY_INSERT tblCustomer OFF;

-- CREATE PROC to get address id
CREATE PROC emilyd61_uspGetAddressID
@Street varchar (100),
@Zipcode int,
@Add_ID int OUTPUT
AS
SET @Add_ID = (SELECT AddressID FROM tblAddress 
				WHERE StreetAddress = @Street AND Zip = @Zipcode)
IF @Add_ID IS NULL
BEGIN PRINT '@Add_ID cannot be null. ERROR.'
	RAISERROR ('@Add_ID is unique key, it cannot be null.',11,1)
	RETURN
	END

-- get Product Type
CREATE PROC emilyd61_uspGetProductTypeID
@ProdTypeName varchar(100),
@ProdTypeDesc varchar(100),
@PrdoTypeID int OUTPUT
AS
SET @PrdoTypeID = (SELECT ProductTypeID FROM tblProductType 
					WHERE ProductTypeID = @PrdoTypeID)
IF @PrdoTypeID IS NULL
BEGIN PRINT '@PrdoTypeID cannot be null. ERROR.'
	RAISERROR ('@PrdoTypeID is unique key, it cannot be null.',11,1)
	RETURN
	END

/* No under 18 years old seller*/
CREATE FUNCTION fn_No18Seller()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (SELECT *
			FROM tblOffering O JOIN tblCustomer C ON O.SellerID = C.CustomerID
							JOIN tblProduct P ON O.ProductID = P.ProductID
							AND C.DOB > (SELECT GetDate() - (365.25 * 18)))
SET @Ret = 1
RETURN @Ret
END
GO

ALTER TABLE tblOffering
ADD CONSTRAINT CK_No18Seller
CHECK (dbo.fn_No18Seller() = 0)

/*
-- Ken
Store Proc for inserting the products (Populates products) with CASE statements
I randomly assign a type string during the insert.
So I put the rand() and case for selecting the type in the while loop*/

ALTER /*CREATE*/ PROC long27km_InsertProduct
@ProductTypeName varchar(50),
@ProductName varchar(50),
@ProductDesc varchar(50)
AS
BEGIN
	DECLARE @P_ID INT;

	EXEC emilyd61_uspGetProductTypeID @ProdTypeName = @ProductTypeName, @ProdTypeID = @P_ID OUTPUT;

	IF @P_ID IS NULL
	BEGIN
		RAISERROR ('ProductTypeID not found!', 11, 1);
		RETURN
	END

	BEGIN TRAN

	INSERT INTO tblProduct (ProductName, ProductDesc, ProductTypeID) VALUES (@ProductName, @ProductDesc, @P_ID);
	
	IF @@ERROR <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
END

GO

CREATE TABLE WorkingProduct(
	ProductID INT PRIMARY KEY IDENTITY(1,1),
	ProductName varchar(100),
	ProductDesc varchar(100)
)

DELETE FROM WorkingProduct;

INSERT INTO WorkingProduct (ProductName, ProductDesc) SELECT ProductName, ProductDescr 
	FROM RAW_PRODUCT;


SELECT * FROM WorkingProduct;

DECLARE @ROW_COUNT INT = (SELECT COUNT(*) FROM WorkingPRODUCT);

WHILE @ROW_COUNT > 0
BEGIN

	DECLARE @TYPE INT = (SELECT (RAND()-0.0001)*10);
	
	DECLARE @TYPE_NAME varchar(50) = (SELECT CASE 
		WHEN @TYPE < 3 THEN 'Plant' 
		WHEN @TYPE > 6 THEN 'Seed'
		ELSE
			'Greens'
		END)

	PRINT @TYPE_NAME

	DECLARE @P_ID INT = (SELECT MIN(ProductID) FROM WorkingProduct)

	DECLARE @ProductName varchar(100) = (SELECT ProductName FROM WorkingProduct WHERE ProductID = @P_ID);

	DECLARE @ProductDesc varchar(100) = (SELECT ProductDesc FROM WorkingProduct WHERE ProductID = @P_ID);

	EXEC long27km_InsertProduct @ProductTypeName = @TYPE_NAME, @ProductName = @ProductName, @ProductDesc = @ProductDesc

	DELETE FROM WorkingProduct WHERE ProductID = @P_ID;

	SET @ROW_COUNT = @ROW_COUNT - 1;
END

/*Insert Address & Insert the Customers*/

CREATE PROC [dbo].[long27km_uspInsertAddress]
@AddressID INT = NULL,
@StreetAddress varchar(50),
@City varchar(50),
@State varchar(50),
@Zip varchar(15),
@ID INT OUTPUT
AS
BEGIN
	SET @ID = (SELECT TOP 1 A.AddressID FROM tblAddress A WHERE A.StreetAddress = @StreetAddress AND A.City = @City AND A.[State] = @State AND A.Zip = @Zip)
	
	IF @ID IS NOT NULL
	BEGIN
		RETURN;
	END		 
	IF @AddressID IS NULL
	BEGIN
		INSERT INTO tblAddress (StreetAddress, City, [State], Zip) VALUES (@StreetAddress, @City, @State, @Zip);
		SET @ID = (SELECT SCOPE_IDENTITY()); 
	END
	ELSE
	BEGIN
		SET IDENTITY_INSERT tblAddress ON;
			INSERT INTO tblAddress (AddressID, StreetAddress, City, [State], Zip) VALUES (@AddressID, @StreetAddress, @City, @State, @Zip);
		SET @ID = @AddressID; 
		SET IDENTITY_INSERT tblAddress OFF;
	END
END
GO
CREATE PROC [dbo].[long27km_uspInsertCustomer]
@CustID INT = NULL,
@AddressID INT = NULL,
@FName varchar(100),
@LName varchar(100), 
@Phone varchar(20),
@Email varchar(256),
@DOB DATE,
@StreetAddress varchar(50),
@City varchar(50),
@State varchar(50),
@Zip varchar(15)
AS
BEGIN
	
	EXEC long27km_uspInsertAddress @AddressID=@AddressID, @StreetAddress = @StreetAddress, @City= @City, @State = @State, @Zip = @Zip, @ID = @AddressID OUTPUT
	IF @CustID IS NULL
	BEGIN
	
		INSERT INTO tblCustomer (FirstName, LastName, PhoneNumber, Email, DOB, AddressID) VALUES (@FName, @LName, @Phone, @Email, @DOB, @AddressID)
	END
	ELSE
	BEGIN
		SET IDENTITY_INSERT tblCustomer ON;
		INSERT INTO tblCustomer (CustomerID, FirstName, LastName, PhoneNumber, Email, DOB, AddressID) VALUES (@CustID, @FName, @LName, @Phone, @Email, @DOB, @AddressID)
		SET IDENTITY_INSERT tblCustomer OFF;
	END
END
GO

/*
-- Joseph Chou
Group customers into generations based on their date of birth:
- GI Generation:     1901 - 1924
- Silent Generation: 1925 - 1945
- Baby Boomers:      1946 - 1964
- Generation X:      1965 - 1979
- Generation Y:      1980 - 1994
- Generatino Z:      1995 - Present
*/

SELECT (CASE
	WHEN Year(DOB) BETWEEN 1901 AND 1924
		THEN 'GI Generation'
	WHEN Year(DOB) BETWEEN 1925 AND 1945
		THEN 'Silent Generation'
	WHEN Year(DOB) BETWEEN 1946 AND 1964
		THEN 'Baby Boomers'
	WHEN Year(DOB) BETWEEN 1965 AND 1979
		THEN 'Generation X'
	WHEN Year(DOB) BETWEEN 1980 AND 1994
		THEN 'Generation Y'
	WHEN Year(DOB) >= 1995
		THEN 'Generation Z'
	ELSE 'Other'
END) AS 'Generation', COUNT(*) AS 'TotalNum'
FROM tblCustomer
GROUP BY (CASE
	WHEN Year(DOB) BETWEEN 1901 AND 1924
		THEN 'GI Generation'
	WHEN Year(DOB) BETWEEN 1925 AND 1945
		THEN 'Silent Generation'
	WHEN Year(DOB) BETWEEN 1946 AND 1964
		THEN 'Baby Boomers'
	WHEN Year(DOB) BETWEEN 1965 AND 1979
		THEN 'Generation X'
	WHEN Year(DOB) BETWEEN 1980 AND 1994
		THEN 'Generation Y'
	WHEN Year(DOB) >= 1995
		THEN 'Generation Z'
	ELSE 'Other'
END)
ORDER BY TotalNum DESC


/*
-- Josiah
Products account CASE statement: based on the typeID to account how many products we have
1) Fruits
2) Veggies
3) Grains
3) Others
*/
SELECT (CASE
	WHEN ProductTypeName IN ('Berry', 'Drupe', 'Dry Fruits')
	THEN 'Fruits Type'
	WHEN ProductTypeName = 'Grain'
	THEN 'Grains'
	WHEN ProductTypeName IN ('Legume', 'Greens')
	THEN 'Green Veggies'
	ELSE 'Others'
	END)
AS 'PlantingType', COUNT(*) 'TotalNum'
FROM tblProduct P JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
GROUP BY (CASE
	WHEN ProductTypeName IN ('Berry', 'Drupe', 'Dry Fruits')
	THEN 'Fruits Type'
	WHEN ProductTypeName = 'Grain'
	THEN 'Grains'
	WHEN ProductTypeName IN ('Legume', 'Greens')
	THEN 'Green Veggies'
	ELSE 'Others'
	END)
ORDER BY TotalNum DESC

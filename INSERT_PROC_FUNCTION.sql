USE [GREEN_THUMB]

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
GO

ALTER table [dbo].[tblCustomer]
ALTER column [PhoneNumber] varchar (20)

INSERT INTO [WorkingCustomerData] (
[CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum])
SELECT [CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum]
FROM [RAW_CUSTOMER]

INSERT INTO [dbo].[tblProductType] ([ProductTypeName], [ProductTypeDesc])
SELECT [ProductTypeName], [ProductTypeDescr]
FROM [dbo].[RAW_PRODUCT_TYPE]

INSERT INTO tblAddress(StreetAddress, City, [State], Zip)
SELECT CustomerAddress, CustomerCity, CustomerState, CustomerZIP
FROM [dbo].[WorkingCustomerData]

DELETE FROM tblAddress;
DELETE FROM tblCustomer;
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

-- insert customer info
/*DECLARE @Run INT = (SELECT COUNT(*) FROM [WorkingCustomerData])
DECLARE @ID INT
DECLARE @CID INT
DECLARE @FName varchar(50)
DECLARE @LName varchar(50)
DECLARE @PNum varchar(50)
DECLARE @EMAIL varchar(100)
DECLARE @D_OB date
DECLARE @AddID INT
DECLARE @ST varchar(50)
DECLARE @ZipC int

WHILE @Run > 0
BEGIN
SET @ID = (SELECT MIN(CustomerID) FROM [WorkingCustomerData])
SET @FName = (SELECT [CustomerFname] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @LName = (SELECT [CustomerLname] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @PNum = (SELECT [PhoneNum] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @EMAIL = (SELECT [Email] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @D_OB = (SELECT [DateOfBirth] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @AddID = (SELECT AddressID FROM tblAddress WHERE AddressID = @AddID)

EXEC uspGetAddressID
@Street = @ST,
@Zipcode = @ZipC,
@Add_ID = @AddID OUTPUT

BEGIN TRAN G1
INSERT INTO tblCustomer (FirstName, LastName, PhoneNumber, Email, DOB, AddressID)
VALUES (@FName, @LName, @PNum, @EMAIL, @D_OB, @AddID)
SET @CID = (SELECT SCOPE_IDENTITY())

IF @@ERROR <> 0
ROLLBACK TRAN G1
ELSE
COMMIT TRAN G1

SET @Run = @Run -1
END
*/
/*
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

CREATE PROC [dbo].[long27km_usp_SimpleETLCustomer]
@CustID INT
AS
BEGIN
DECLARE @Fname varchar(50) = (SELECT CustomerFname FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @Lname varchar(50) = (SELECT CustomerLname FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @Address varchar(100) = (SELECT CustomerAddress FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @City varchar(50) = (SELECT CustomerCity FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @State varchar(50) = (SELECT CustomerState FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @Zip varchar(15) = (SELECT CustomerZIP FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @Email varchar(256) = (SELECT Email FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @DOB DATE = (SELECT DateOfBirth FROM WorkingCustomerData WHERE CustomerID = @CustID);
DECLARE @Phone varchar(20) = (SELECT PhoneNum FROM WorkingCustomerData WHERE CustomerID = @CustID);

EXEC long27km_uspInsertCustomer  @CustID = @CustID, @FName = @FName, @LName = @LName, @StreetAddress = @Address, @City = @City, @State = @State, @Zip = @Zip, @Email = @Email, @DOB = @DOB, @Phone = @Phone

DELETE FROM WorkingCustomerData WHERE CustomerID = @CustID;

END

GO

DECLARE @ROW_COUNT INT = (SELECT COUNT(*) FROM WorkingCustomerData); 
WHILE @ROW_COUNT > 0
BEGIN

DECLARE @CustID INT = (SELECT MIN(CustomerID) FROM WorkingCustomerData);

EXEC long27km_usp_SimpleETLCustomer @CustID = @CustID;

SET @ROW_COUNT = @ROW_COUNT - 1;

END
*/

-- get Product Type
ALTER /*CREATE*/ PROC emilyd61_uspGetProductTypeID
@ProdTypeName varchar(100),
@ProdTypeID int OUTPUT
AS
SET @ProdTypeID = (SELECT ProductTypeID FROM tblProductType 
					WHERE ProductTypeName LIKE '%'+@ProdTypeName+'%')
IF @ProdTypeID IS NULL
	BEGIN 
		RAISERROR ('@ProdTypeName not found',11,1)
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

SELECT * FROM RAW_PRODUCT
SELECT * FROM RAW_PRODUCT_TYPE
GO
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

CREATE PROC emilyd61_uspGetCustTypeID
@CustTypeName varchar(100),
@CustTypeDescr varchar(100),
@CustTID int output
AS 
SET @CustTID = (SELECT CustTypeID FROM tblCustomerType WHERE CustTypeName = @CustTypeName)
IF @CustTID IS NULL
BEGIN RAISERROR ('@CustomerType not found',11,1)
RETURN END

INSERT INTO tblCustomerType (CustTypeName, CustTypeDesc)
SELECT [CustomerType], [CustTypeDescr]
FROM RAW_CUSTTYPE

DELETE FROM workingCustCustType
CREATE TABLE workingCustCustType (
CustCustTypeID INT IDENTITY(1,1) PRIMARY KEY not null,
CustFname varchar(250) not null,
CustLname varchar(250) not null,
StartDate DATE,
EndDate DATE
)

insert into workingCustCustType (CustFname, CustLname)
select [FirstName], [LastName]
from tblCustomer

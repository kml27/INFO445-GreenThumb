USE GREEN_THUMB
GO

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

-- create customer type 
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

CREATE PROCEDURE emilyd61_uspGetCustID
@Fname varchar(50),
@Lname varchar(50),
@Dob DATE,
@CustID INT OUTPUT
AS
SET @CustID = (SELECT CustomerID FROM tblCustomer WHERE FirstName = @Fname AND LastName = @Lname AND DOB = @Dob)

GO

CREATE PROCEDURE emilyd61_uspGetReviewID
@ReTitle varchar(100),
@CustFname varchar(100),
@CustLname varchar(100),
@CustDOB DATE,
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB DATE,
@ReID INT OUTPUT
AS
DECLARE @CID INT
DECLARE @SID INT

EXEC emilyd61_uspGetCustID
@Fname = @CustFname,
@Lname = @CustLname,
@Dob = @CustDOB,
@CustID = @CID OUTPUT

EXEC emilyd61_uspGetCustID
@Fname = @SellFname,
@Lname = @SellLname,
@Dob = @SellDOB,
@CustID = @SID OUTPUT

SET @ReID = (SELECT ReviewID FROM tblReview WHERE ReviewTitle = @ReTitle AND CustomerID = @CID AND SellerID = @SID)

GO

CREATE PROCEDURE emilyd61_uspGetProdID
@ProdName varchar(100),
@ProdID INT OUTPUT
AS
SET @ProdID = (SELECT ProductID FROM tblProduct WHERE ProductName = @ProdName)

GO

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

/* No under 18 years old seller*/
CREATE FUNCTION fn_No18Seller()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (SELECT *
			FROM tblOffering O JOIN tblCustomer C ON O.SellerID = C.CustomerID
							JOIN tblProduct P ON O.ProductID = P.ProductID
			WHERE C.DOB < (SELECT GetDate() - (365.25 * 18)))
SET @Ret = 1
RETURN @Ret
END
GO

ALTER TABLE tblOffering
ADD CONSTRAINT CK_No18Seller
CHECK (dbo.fn_No18Seller() = 0)

/*All the total price in each order should at least $10.00 (min pay is 10.00)*/
CREATE FUNCTION fn_minOrderPay10()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (SELECT *
			FROM tblOrder ORD JOIN tblLineItem L ON ORD.OrderID = L.OrderID
			JOIN tblOffering O ON L.OfferingID = O.OfferingID
			GROUP BY ORD.OrderID
			HAVING SUM(O.Price) < 10
)
SET @Ret = 1
RETURN @Ret
END
GO

ALTER TABLE tblOrder
ADD CONSTRAINT CK_minPayLessThan10
CHECK (dbo.fn_minOrderPay10() = 0)

-- insert customer info from RAW_DATA
CREATE PROCEDURE emilyd61_uspInsertCustWapperfromWorkingData
@Run INT
AS
DECLARE @NUM INT = (SELECT COUNT(*) FROM [WorkingCustomerData])
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

EXEC emilyd61_uspGetAddressID
@Street = @ST,
@Zipcode = @ZipC,
@Address_ID = @AddID

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
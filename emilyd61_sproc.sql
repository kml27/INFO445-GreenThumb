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
CREATE PROC emilyd61_uspGetProductTypeID
@ProdTypeName varchar(100),
@ProdTypeDesc varchar(100),
@ProdTypeID int OUTPUT
AS
SET @ProdTypeID = (SELECT ProductTypeID FROM tblProductType 
					WHERE ProductTypeName LIKE '%'+@ProdTypeName+'%')

GO

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
ALTER PROC emilyd61_uspGetAddressID
@Street varchar (100),
@City varchar (100),
@State varchar (100),
@Zipcode int,
@Address_ID int OUTPUT
AS
SET @Address_ID = (SELECT AddressID FROM tblAddress 
				WHERE StreetAddress = @Street AND City = @City AND [State] = @State AND Zip = @Zipcode)

GO

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

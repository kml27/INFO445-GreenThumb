USE [GREEN_THUMB]

SELECT * FROM tblAddress

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
drop table [WorkingCustomerData]

ALTER table [dbo].[tblCustomer]
ALTER column [PhoneNumber] varchar (20)

INSERT INTO [WorkingCustomerData] (
[CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum])
SELECT [CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum]
FROM [RAW_CUSTOMER]


INSERT INTO tblAddress(StreetAddress, City, [State], Zip)
SELECT CustomerAddress, CustomerCity, CustomerState, CustomerZIP
FROM [dbo].[WorkingCustomerData]

-- CREATE PROC to get address id
ALTER PROC uspGetAddressID
@Street varchar (100),
@Zipcode int,
@Add_ID int OUTPUT
AS
SET @Add_ID = (SELECT AddressID FROM tblAddress 
				WHERE StreetAddress = @Street AND Zip = @Zipcode)

-- insert customer info
DECLARE @Run INT = (SELECT COUNT(*) FROM [WorkingCustomerData])
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


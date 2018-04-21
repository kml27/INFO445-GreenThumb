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
/*
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
		/*PRINT 'Address found in DB, returning existing entry';*/
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


CREATE /*CREATE*/ PROC [dbo].[long27km_usp_SimpleETLCustomer]
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







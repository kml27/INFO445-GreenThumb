USE [GREEN_THUMB]
GO

CREATE TYPE CustAddr AS TABLE(
	AddressID INT,
	StreetAddress varchar(50),
	City varchar(50),
	[State] varchar(50),
	Zip varchar(15)
	);
GO

CREATE /*ALTER*/ PROC [dbo].[long27km_uspInsertAddressTVP]
@AddressTVP CustAddr READONLY,
@ID INT OUTPUT
AS
BEGIN
	
	DECLARE @AddressID INT = (SELECT AddressID FROM @AddressTVP);
	DECLARE @StreetAddress varchar(50) = (SELECT StreetAddress FROM @AddressTVP);
	DECLARE @City varchar(50) = (SELECT TOP 1 City FROM @AddressTVP);
	DECLARE @State varchar(50) = (SELECT TOP 1 [State] FROM @AddressTVP);
	DECLARE @Zip varchar(15) = (SELECT TOP 1 Zip FROM @AddressTVP);

	SET @ID = (SELECT TOP 1 AddressID 
		FROM tblAddress A
		WHERE 
		A.StreetAddress = @StreetAddress AND
		A.City = @City AND
		A.[State] = @State AND
		A.Zip = @Zip);
			
	IF @ID IS NOT NULL
	BEGIN
		PRINT 'Address found in DB, returning existing entry';
		RETURN;
	END		 
	ELSE
	BEGIN
		IF @AddressID IS NULL
		BEGIN
			INSERT INTO tblAddress (StreetAddress, City, [State], Zip) SELECT TOP 1 StreetAddress, City, [State], Zip FROM @AddressTVP;
			SET @ID = (SELECT SCOPE_IDENTITY()); 
		END
		ELSE
		BEGIN
			SET IDENTITY_INSERT tblAddress ON;
				INSERT INTO tblAddress (AddressID, StreetAddress, City, [State], Zip) SELECT TOP 1 AddressID, StreetAddress, City, [State], Zip FROM @AddressTVP;
			SET @ID = @AddressID; 
			SET IDENTITY_INSERT tblAddress OFF;
		END
	END
END

GO

USE [GREEN_THUMB]
GO

	ALTER DATABASE GREEN_THUMB ADD FILEGROUP gt_mod CONTAINS MEMORY_OPTIMIZED_DATA;

	ALTER DATABASE GREEN_THUMB ADD FILE (name='gt_mod1', filename='c:\sql\gt_mod1') TO FILEGROUP gt_mod;

/*	DISABLE TRIGGER ALL ON DATABASE;
	GO
	*/

	CREATE TYPE dbo.typeTableCustRow
		AS TABLE(
			CustomerID INT NOT NULL INDEX idx1, 
			CustomerFname varchar(50), 
			CustomerLname varchar(50), 
			CustomerAddress  varchar(100), 
			CustomerCity varchar(50), 
			CustomerState varchar(50), 
			CustomerZIP INT, 
			Email  varchar(100), 
			DateOfBirth DATE, 
			PhoneNum varchar(20)
		)

		/*DDL trigger wont allow with memory_optimized*/
		/*WITH
			(MEMORY_OPTIMIZED = ON);*/

	GO

	/*ENABLE TRIGGER ALL ON DATABASE;

	GO*/


CREATE /*ALTER*/ PROC [dbo].[long27km_uspInsertCustomerTVP]
@CustRow [dbo].[typeTableCustRow] READONLY
AS
BEGIN
	
	DECLARE @AddressTVP [dbo].[CustAddr];
	DELETE FROM @AddressTVP;

	DECLARE @AddressID INT

	INSERT INTO @AddressTVP SELECT NULL, CustomerAddress, CustomerCity, CustomerState, CustomerZIP FROM @CustRow;

	EXEC long27km_uspInsertAddressTVP @AddressTVP=@AddressTVP, @ID = @AddressID OUTPUT

	DECLARE @CustID INT = (SELECT CustomerID FROM @CustRow);

	IF @CustID IS NULL
	BEGIN
	
		INSERT INTO tblCustomer (FirstName, LastName, PhoneNumber, Email, DOB, AddressID) SELECT CustomerFName, CustomerLName, PhoneNum, Email, DateOfBirth, @AddressID FROM @CustRow;
	END
	ELSE
	BEGIN
		SET IDENTITY_INSERT tblCustomer ON;

		INSERT INTO tblCustomer (CustomerID, FirstName, LastName, PhoneNumber, Email, DOB, AddressID) SELECT CustomerID, CustomerFName, CustomerLName, PhoneNum, Email, DateOfBirth, @AddressID FROM @CustRow;

		SET IDENTITY_INSERT tblCustomer OFF;
	END

END

GO
/*
USE GREEN_THUMB;

SELECT * FROM WorkingCustomerData;

SELECT * FROM tblCustomer;

ALTER TABLE tblCustomer
	ALTER COLUMN Email varchar(256);

ALTER TABLE tblAddress
	ALTER COLUMN Zip varchar(15)

SELECT * FROM tblAddress;

GO

CREATE PROC long27km_uspInsertAddress
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
		PRINT 'Address found in DB, returning existing entry';
		RETURN;
	END		 

	IF @AddressID IS NULL
	BEGIN
		INSERT INTO tblAddress (StreetAddress, City, [State], Zip) VALUES (@StreetAddress, @City, @State, @Zip);
		SET @ID = (SELECT SCOPE_IDENTITY()); 
	END
	ELSE
	BEGIN
		SET IDENTITY_INSERT tblAddress OFF;
			INSERT INTO tblAddress (AddressID, StreetAddress, City, [State], Zip) VALUES (@AddressID, @StreetAddress, @City, @State, @Zip);
		SET @ID = @AddressID; 
		SET IDENTITY_INSERT tblAddress ON;
	END
END

GO

CREATE PROC long27km_uspInsertCustomer
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
	
	IF @CustID IS NULL
	BEGIN
		EXEC long27km_uspInsertAddress @AddressID=@AddressID, @StreetAddress = @StreetAddress, @City= @City, @State = @State, @Zip = @Zip, @ID = @AddressID OUTPUT

		INSERT INTO tblCustomer (FirstName, LastName, PhoneNumber, Email, DOB, AddressID) VALUES (@FName, @LName, @Phone, @Email, @DOB, @AddressID)
	END
	ELSE
	BEGIN
		SET IDENTITY_INSERT tblCustomer OFF;

		INSERT INTO tblCustomer (CustomerID, FirstName, LastName, PhoneNumber, Email, DOB, AddressID) VALUES (@CustID, @FName, @LName, @Phone, @Email, @DOB, @AddressID)

		SET IDENTITY_INSERT tblCustomer ON;
	END
END

GO
*/

/*
	table variables used in stored procedures cause fewer recompilations of the stored procedures than when temporary tables are used when there are no cost-based choices that affect performance.
Transactions involving table variables last only for the duration of an update on the table variable. Therefore, table variables require less locking and logging resources.
	*/

	/* Enable MEMORY_OPTIMIZED_DATA */

DELETE FROM WorkingCustomerData;
GO

INSERT INTO [WorkingCustomerData] (
[CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum])
SELECT [CustomerFname], [CustomerLname], [CustomerAddress], [CustomerCity], [CustomerState],
[CustomerZIP], [Email], [DateOfBirth], [PhoneNum]
FROM [RAW_CUSTOMER]

/*DROP TABLE tblCustomer;*/
GO

DELETE FROM tblCustomer;
GO

SELECT * FROM tblCUstomer;

SELECT * FROM WorkingCustomerData ORDER BY CustomerID ASC;

/*Table Valued Parameters from User Defined Table Types can be passed to SPs even if TABLE can't be*/

DECLARE @ROW_COUNT INT = (SELECT COUNT(*) FROM WorkingCustomerData);

WHILE @ROW_COUNT > 0
BEGIN
	
	DECLARE @CustRow [dbo].[typeTableCustRow]

	DECLARE @CustID INT = (SELECT MIN(CustomerID) FROM WorkingCustomerData);

	INSERT INTO @CustRow SELECT * FROM WorkingCustomerData WHERE CustomerID = @CustID;

	EXEC long27km_uspInsertCustomerTVP @CustRow = @CustRow

	DELETE FROM @CustRow;
/*
	IF @@ERROR <> 0
	BEGIN
		PRINT 'ERROR OCCURRED DURING ETL'
		BREAK
		RETURN
	END
*/		
	DELETE FROM WorkingCustomerData WHERE CustomerID = @CustID;

	SET @ROW_COUNT = @ROW_COUNT - 1;
	
END

SELECT * FROM tblCustomer;

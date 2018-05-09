USE GREEN_THUMB;

DECLARE @ROW_COUNT INT = 30000

WHILE @ROW_COUNT > 0
BEGIN
	
	DECLARE @NUM_CUST INT = (SELECT COUNT(*) FROM tblCustomer)

	DECLARE @MIN_CUST_ID INT = (SELECT MIN(CustomerID) from tblCustomer);

	DECLARE @CustID1 INT = (SELECT MIN(CustomerID)+RAND()*@NUM_CUST FROM tblCustomer);

WHILE NOT EXISTS (SELECT * FROM tblCUSTOMER WHERE CUSTOMERID = @CustID1)
BEGIN
	SET @CustID1 = (RAND()*@NUM_CUST+@MIN_CUST_ID)
END

	DECLARE @CustID2 INT = (SELECT MIN(CustomerID)+RAND()*@NUM_CUST FROM tblCustomer);

WHILE NOT EXISTS (SELECT * FROM tblCUSTOMER WHERE CUSTOMERID = @CustID2)
BEGIN
	SET @CustID2 = (RAND()*@NUM_CUST+@MIN_CUST_ID)
END

	DECLARE @C_FName varchar(50) = (SELECT FirstName from tblCustomer WHERE CustomerID = @CustID1)
	DECLARE @C_LName varchar(50) = (SELECT FirstName from tblCustomer WHERE CustomerID = @CustID2)

	DECLARE @NUM_ADDRESS INT = (SELECT COUNT(AddressID) FROM tblAddress)
	DECLARE @MIN_ADDRESS INT = (SELECT MIN(ADDRESSID) FROM tblAddress)

	DECLARE @A_ID INT = (SELECT AddressID FROM tblAddress WHERE AddressID=@MIN_ADDRESS+RAND()*@NUM_ADDRESS);

WHILE NOT EXISTS (SELECT * FROM tblAddress WHERE AddressID = @A_ID)
BEGIN
	SET @A_ID = (RAND()*@NUM_ADDRESS+@MIN_ADDRESS)
END
	DECLARE @Street varchar(100) = (SELECT StreetAddress FROM tblAddress WHERE AddressID = @A_ID)

	DECLARE @City varchar(100) = (SELECT City FROM tblAddress WHERE AddressID = @A_ID)

	DECLARE @State varchar(100) = (SELECT [State] FROM tblAddress WHERE AddressID = @A_ID)
	
	DECLARE @Zip varchar(20) = (SELECT Zip FROM tblAddress WHERE AddressID = @A_ID)

	DECLARE @Phony VARCHAR(20) = CAST(100+(RAND()*899) AS INT)+'-'+CAST(100+(RAND()*899) AS INT)+'-'+CAST(1000+(RAND()*8999) AS INT);

	DECLARE @email_host varchar(256) = (SELECT SUBSTRING(email, CHARINDEX('@', email), LEN(email)) from tblCustomer WHERE CustomerID = @CustID1)

	DECLARE @NewEmail varchar(256) = (@C_FName+@C_LName+CAST(CAST((RAND()*9999) AS INT) AS varchar(4))+@email_host);

	DECLARE @NewDOB Date = (SELECT GetDate() - (16+(RAND()*20)*356.25))

	EXEC long27km_uspInsertCustomer @CustID=NULL, @AddressID=@A_ID, @FName=@C_FName, @LName=@C_LName, @Phone=@Phony, @Email=@NewEmail, @DOB=@NewDOB, @StreetAddress = @Street, @City=@City, @State = @State, @Zip = @Zip

	SET @ROW_COUNT = @ROW_COUNT - 1;
	
END

SELECT COUNT(*) FROM tblCustomer;
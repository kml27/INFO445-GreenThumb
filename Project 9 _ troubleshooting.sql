USE GREEN_THUMB
GO

--[dbo].[emilyd61_uspWRAPPER_CalluspInsertReview]
ALTER PROCEDURE [dbo].[emilyd61_uspWRAPPER_CalluspInsertReview]
@ROW_COUNT INT
AS
	DECLARE @NUM_Review INT = (SELECT COUNT(*) FROM tblCustomer)
	DECLARE @CustRow [dbo].[typeTableCustRow]
	DECLARE @CustID INT = (SELECT TOP 1 CustomerID FROM tblCustomer ORDER BY NEWID())
	DECLARE @SellID INT = (SELECT TOP 1 CustomerID FROM tblCustomer ORDER BY NEWID())
	DECLARE @RateID INT = (SELECT TOP 1 RatingID FROM tblRating ORDER BY NEWID())

	DECLARE @CustF varchar(150) = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @CustID)
	DECLARE @CustL varchar(150) = (SELECT LastName FROM tblCustomer WHERE CustomerID = @CustID)
	DECLARE @C_DOB date = (SELECT DOB FROM tblCustomer WHERE CustomerID = @CustID)
	DECLARE @SellF varchar(150) = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @SellID)
	DECLARE @SellL varchar(150) = (SELECT LastName FROM tblCustomer WHERE CustomerID = @SellID)
	DECLARE @S_DOB date = (SELECT DOB FROM tblCustomer WHERE CustomerID = @SellID)
	DECLARE @RName varchar(50) = (SELECT RatingName FROM tblRating WHERE RatingID = @RateID)

	DECLARE @ViewName varchar(250) = (SELECT TOP 1 Title FROM RAW_REVIEW ORDER BY NEWID())
	DECLARE @ViewDetail varchar(250) = (SELECT TOP 1 [Text] FROM RAW_REVIEW ORDER BY NEWID()) 

WHILE @ROW_COUNT > 0
BEGIN
	SET @CustF = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @CustID)
	SET @CustL = (SELECT LastName FROM tblCustomer WHERE CustomerID = @CustID)
	SET @C_DOB = (SELECT DOB FROM tblCustomer WHERE CustomerID = @CustID)
	SET @SellF = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @SellID)
	SET @SellL = (SELECT LastName FROM tblCustomer WHERE CustomerID = @SellID)
	SET @S_DOB = (SELECT DOB FROM tblCustomer WHERE CustomerID = @SellID)
	SET @RName = (SELECT RatingName FROM tblRating WHERE RatingID = @RateID)

	SET @ViewName = (SELECT TOP 1 Title FROM RAW_REVIEW ORDER BY NEWID())
	SET @ViewDetail = (SELECT TOP 1 [Text] FROM RAW_REVIEW ORDER BY NEWID()) 

	EXEC jchou8_uspInsertReview 
	@CustFname = @CustF,
	@CustLname = @CustL,
	@CustDOB = @C_DOB,
	@SellFname = @SellF,
	@SellLname = @SellL,
	@SellDOB = @S_DOB,
	@RateName = @RName,
	@Title = @ViewName,
	@Text = @ViewDetail

	SET @ROW_COUNT = @ROW_COUNT - 1
END

-- [dbo].[jchou8_uspInsertOfferingWrapper]
/*CREATE*/ ALTER PROCEDURE [dbo].[jchou8_uspInsertOfferingWrapper]
@Run INT
AS
DECLARE @SellID INT 
DECLARE @SellCount INT = (SELECT COUNT(*) FROM tblCustomer)
DECLARE @ProdID INT
DECLARE @ProdCount INT = (SELECT COUNT(*) FROM tblProduct)
DECLARE @AddressID INT
DECLARE @AddressCount INT = (SELECT COUNT(*) FROM tblAddress)

DECLARE @SellFname varchar(100)
DECLARE @SellLname varchar(100)
DECLARE @SellDOB DATE

DECLARE @Prod varchar(100)

DECLARE @AddressSt varchar(100)
DECLARE @AddressCity varchar(100)
DECLARE @AddressState varchar(100)
DECLARE @AddressZip INT

DECLARE @Price money

DECLARE @OfferingName varchar(50)
DECLARE @StartDate DATE = GETDATE()

WHILE @Run > 0
BEGIN
	SET @SellID = (SELECT TOP 1 CustomerID FROM tblCustomer ORDER BY NEWID())
	SET @ProdID = (SELECT TOP 1 ProductID FROM tblProduct ORDER BY NEWID())
	SET @AddressID = (SELECT TOP 1 AddressID FROM tblAddress ORDER BY NEWID())

	WHILE NOT EXISTS (
		SELECT * FROM tblCustomerCustomerType CCT
		JOIN tblCustomerType CT ON CCT.CustTypeID = CT.CustTypeID
		WHERE CT.CustTypeName = 'Seller'
		AND CCT.CustomerID = @SellID
	) BEGIN
		 SET @SellID = (SELECT TOP 1 CustomerID FROM tblCustomer ORDER BY NEWID())
	END
	
	SET @SellFname = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @SellID)
	SET @SellLname = (SELECT LastName FROM tblCustomer WHERE CustomerID = @SellID)
	SET @SellDOB = (SELECT DOB FROM tblCustomer WHERE CustomerID = @SellID)

	SET @Prod = (SELECT ProductName FROM tblProduct WHERE ProductID = @ProdID)
	
	SET @AddressSt = (SELECT StreetAddress FROM tblAddress WHERE AddressID = @AddressID)
	SET @AddressCity = (SELECT City FROM tblAddress WHERE AddressID = @AddressID)
	SET @AddressState = (SELECT [State] FROM tblAddress WHERE AddressID = @AddressID)
	SET @AddressZip = (SELECT Zip FROM tblAddress WHERE AddressID = @AddressID)

	SET @Price = CONVERT(MONEY, RAND() * 50)

	SET @OfferingName = LEFT(@Prod + ' from ' + @SellFname + ' ' + @SellLname, 50)

	EXEC jchou8_uspInsertOffering
	@SellFname = @SellFname,
	@SellLname = @SellLname,
	@SellDOB = @SellDOB,
	@ProdName = @Prod,
	@AddSt = @AddressSt,
	@AddCity = @AddressCity,
	@AddState = @AddressState,
	@AddZip = @AddressZip,
	@Price = @Price,
	@Name = @OfferingName,
	@Start = @StartDate

	SET @Run = @Run - 1
END

--[dbo].[josiahc_uspSyntheticDetail]
-- create wrapper
ALTER PROCEDURE [dbo].[josiahc_uspSyntheticDetail]
@numberOfTimes INT
AS

DECLARE @detailTypeNameSynth VARCHAR(50)
DECLARE @unitSynth VARCHAR(500)
DECLARE @detailDescSynth VARCHAR(500)
DECLARE @sellFnameSynth VARCHAR(500)
DECLARE @sellLnameSynth VARCHAR(500)
DECLARE @sellDOBSynth VARCHAR(500)
DECLARE @offeringNameSynth VARCHAR(500)
DECLARE @offeringStartSynth VARCHAR(500)
DECLARE @randID INT
DECLARE @randDT INT

WHILE @numberOfTimes > 0 BEGIN
	WHILE @offeringNameSynth IS NULL BEGIN
		SET @randID = CAST((SELECT RAND() * (SELECT MAX(OfferingID) FROM tblOffering) + 1) AS INT)
		SET @offeringNameSynth = (SELECT OfferingName FROM tblOffering WHERE OfferingID = @randID)
	END
	SET @offeringStartSynth = (SELECT StartDate FROM tblOffering WHERE OfferingID = @randID)
	SET @sellFnameSynth = (SELECT C.FirstName FROM tblOffering O JOIN tblCustomer C ON C.CustomerID = O.SellerID WHERE OfferingID = @randID)
	SET @sellLnameSynth = (SELECT C.LastName FROM tblOffering O JOIN tblCustomer C ON C.CustomerID = O.SellerID WHERE OfferingID = @randID)
	SET @sellDOBSynth = (SELECT C.DOB FROM tblOffering O JOIN tblCustomer C ON C.CustomerID = O.SellerID WHERE OfferingID = @randID)

	SET @randDT = CAST((SELECT RAND() * (SELECT MAX(DetailTypeID) FROM tblDetailType WHERE DetailTypeDesc IS NOT NULL) + 1) AS INT)
	SET @detailTypeNameSynth = (SELECT DetailTypeName FROM tblDetailType WHERE DetailTypeID = @randDT)
	SET @unitSynth = 
		(CASE @detailTypeNameSynth
			WHEN 'color'
				THEN 'none'
			WHEN 'leaf size'
				THEN 'centimetre'
			WHEN 'stalk width'
				THEN 'milimetre'
			WHEN 'leaf density'
				THEN 'square centimeter'
			WHEN 'weight'
				THEN 'kilogram'
			WHEN 'length'
				THEN 'centimetre'
			WHEN 'height'
				THEN 'centimetre'
			WHEN 'width'
				THEN 'centimetre'
			WHEN 'volume'
				THEN 'square centimeter'
			WHEN 'soil pH'
				THEN 'potential of hydrogen'
			WHEN 'stalk color'
				THEN 'none'
		END)
	SET @detailDescSynth = (SELECT RAND() * 99 + 1)
	
	EXECUTE josiahc_uspInsertDetail
		@detailTypeName = @detailTypeNameSynth,
		@unit = @unitSynth,
		@detailDesc = @detailDescSynth,
		@sellFname = @sellFnameSynth,
		@sellLname = @sellLnameSynth,
		@sellDOB = @sellDOBSynth,
		@offeringName = @offeringNameSynth,
		@offeringStart = @offeringStartSynth

	SET @numberOfTimes = @numberOfTimes - 1
END

-- [dbo].[long27km_GEN_INS_FAKE_CUSTOMER]
-- [dbo].[long27km_SYN_POPULATE_CUSTOMER]
ALTER /*CREATE*/ PROC [dbo].[long27km_GEN_INS_FAKE_CUSTOMER]
@CUST_COUNT INT
AS
BEGIN

WHILE @CUST_COUNT > 0
	BEGIN
		
		DECLARE @CustID1 INT = (SELECT TOP 1 CustomerID FROM WorkingCustomerData ORDER BY NEWID());
		DECLARE @CustID2 INT = (SELECT TOP 1 CustomerID FROM WorkingCustomerData ORDER BY NEWID());

		DECLARE @C_FName varchar(50) = (SELECT CustomerFName from WorkingCustomerData WHERE CustomerID = @CustID1)
		DECLARE @C_LName varchar(50) = (SELECT CustomerLName from WorkingCustomerData WHERE CustomerID = @CustID2)

		DECLARE @Street1 varchar(100) = (SELECT TOP 1 SUBSTRING(CustomerAddress, 0, CHARINDEX(CustomerAddress, ' ')) FROM WorkingCustomerData ORDER BY NEWID());

		DECLARE @Street2 varchar(100) = (SELECT TOP 1 SUBSTRING(CustomerAddress, CHARINDEX(CustomerAddress, ' '), LEN(CustomerAddress)) FROM WorkingCustomerData ORDER BY NEWID());

		DECLARE @Street varchar(100) = @Street1 + @Street2

		DECLARE @C_ID INT = (SELECT TOP 1 CustomerID FROM WorkingCustomerData ORDER BY NEWID())

		DECLARE @City varchar(100) = (SELECT CustomerCity FROM WorkingCustomerData WHERE CustomerID = @C_ID)

		DECLARE @State varchar(100) = (SELECT CustomerState FROM WorkingCustomerData WHERE CustomerID = @C_ID)
	
		DECLARE @Zip varchar(20) = (SELECT CustomerZip FROM WorkingCustomerData WHERE CustomerID = @C_ID)

		DECLARE @Phony VARCHAR(20) = CAST(100+(RAND()*899) AS INT)+'-'+CAST(100+(RAND()*899) AS INT)+'-'+CAST(1000+(RAND()*8999) AS INT);

		DECLARE @email_host varchar(256) = (SELECT SUBSTRING(email, CHARINDEX('@', email), LEN(email)) from WorkingCustomerData WHERE CustomerID = @CustID1)

		DECLARE @NewEmail varchar(256) = (@C_FName+@C_LName+CAST(CAST((RAND()*9999) AS INT) AS varchar(4))+@email_host);

		DECLARE @NewDOB Date = (SELECT GetDate() - (16+(RAND()*20)*356.25))

		EXEC long27km_uspInsertCustomer @CustID=NULL, @AddressID=NULL, @FName=@C_FName, @LName=@C_LName, @Phone=@Phony, @Email=@NewEmail, @DOB=@NewDOB, @StreetAddress = @Street, @City=@City, @State = @State, @Zip = @Zip

		END

		SET @CUST_COUNT = @CUST_COUNT - 1;
	
		DECLARE @DELAY_DURATION VARCHAR(8) = '0:00.'+CAST(CAST((SELECT RAND()*250) AS INT) AS VARCHAR(4))

		WAITFOR DELAY @DELAY_DURATION

END

ALTER /*CREATE*/ PROC [dbo].[long27km_SYN_POPULATE_CUSTOMER]
AS
BEGIN

	DECLARE @RAND_CUST_COUNT INT = RAND()*1000;
	
	/*is there a way to execute these as if I ran these from multiple new query windows?*/
	EXEC long27km_GEN_INS_FAKE_CUSTOMER @CUST_COUNT = @RAND_CUST_COUNT

END
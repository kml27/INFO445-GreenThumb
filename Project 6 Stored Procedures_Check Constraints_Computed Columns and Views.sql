/*Project 6: Stored Procedures, Check Constraints, Computed Columns and Views */
USE GREEN_THUMB
GO
/*1) Stored procedure*/
-- Emily Ding
-- insert an order by get the exist CustomerID
CREATE PROCEDURE emilyd61_populateOrder
@F_Name varchar(50),
@L_Name varchar(50),
@D_OB DATE,
@DTime DATETIME,
@OrderID INT OUTPUT
AS
DECLARE @CID INT

EXEC emilyd61_uspGetCustID
@Fname = @F_Name,
@Lname = @L_Name,
@Dob = @D_OB,
@CustID = @CID OUTPUT

IF @CID IS NULL
 BEGIN
 PRINT '@CID is NULL and this is not good'
 RAISERROR ('CustomerID populating @CID was not found', 11,1)
 RETURN 
 END

BEGIN TRAN G1
INSERT INTO tblORDER (CustomerID, OrderDateTime)
VALUES (@CID, @DTime)

IF @@ERROR <> 0
 ROLLBACK TRAN G1
ELSE 
 SET @OrderID = (SELECT SCOPE_IDENTITY())
 COMMIT TRAN T1
GO

-- Insert customer information from RAW_DATA which converted as WorkingCustomerData
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



/*2) Check constraint*/
-- Emily Ding
/* No under 18 years old seller*/
ALTER FUNCTION fn_No18Seller()
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
			HAVING SUM(O.Price) < 10)
SET @Ret = 1
RETURN @Ret
END
GO

ALTER TABLE tblOrder
ADD CONSTRAINT CK_minPayLessThan10
CHECK (dbo.fn_minOrderPay10() = 0)


/*3) Computed column*/
-- Emily Ding
/*Customer age*/
ALTER FUNCTION fn_customerAge(@CustID INT)
RETURNS INT
AS
BEGIN
	DECLARE @Ret INT
	SET @Ret = (SELECT DATEDIFF(YEAR, DOB, GETDATE()) AS Age
				FROM tblCustomer C WHERE CustomerID = @CustID)
RETURN @Ret
END
-- Alter table
ALTER TABLE tblCustomer
ADD CustAge AS (dbo.fn_customerAge(CustomerID))

/*Sell Tax rate: Seattle, it's 10.1% */
ALTER FUNCTION fn_SalesTax(@OffID INT)
RETURNS Money
AS
BEGIN
	DECLARE @Ret Money
	SET @Ret = (SELECT Price * .101 AS TaxFee
				FROM tblOffering WHERE OfferingID = @OffID)
RETURN @Ret
END
-- Alter table
ALTER TABLE tblOffering
Add SellTaxFee AS (dbo.fn_SalesTax(OfferingID))

/*4) View*/
-- Emily Ding
/*How many customers who age over 50 years old buy 'Gears' products over 100 dollars in 1 order
as well as buy all the products over 1000 dollors including the 'Seed'*/

CREATE VIEW TotalCustomerNumOver50
AS
SELECT COUNT(C.CustomerID) AS TotalCustNum
FROM tblCustomer C
	JOIN tblOrder ORD ON C.CustomerID = ORD.CustomerID
	JOIN tblLineItem L ON L.OrderID = ORD.OrderID
	JOIN tblOffering O ON L.OfferingID = O.OfferingID
	JOIN tblProduct P ON O.ProductID = P.ProductID
	JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
WHERE C.DOB > (SELECT GetDate() - (365.25 * 50)) AND
	PT.ProductTypeName = 'Seed' AND
	C.CustomerID IN	(SELECT C.CustomerID
					FROM  tblCustomer C
					JOIN tblOrder ORD ON C.CustomerID = ORD.CustomerID
					JOIN tblLineItem L ON L.OrderID = ORD.OrderID
					JOIN tblOffering O ON L.OfferingID = O.OfferingID
					JOIN tblProduct P ON O.ProductID = P.ProductID
					JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
					WHERE PT.ProductTypeName = 'Gears'
					GROUP BY C.CustomerID
					HAVING SUM(O.Price) > 100 AND COUNT(ORD.OrderID) = 1)
GROUP BY C.CustomerID
HAVING SUM(O.Price) > 1000

/*How many '5 stars' reviewed by 'Loyal' customers
who also are sellers that sold 10000 dollars*/
CREATE VIEW TotalCustSellerNum5star
AS
SELECT COUNT(C.CustomerID) AS TotalCustSellerNum
FROM tblCustomer C JOIN tblCustomerCustomerType CCT
	ON C.CustomerID = CCT.CustomerID
	JOIN tblCustomerType CT ON CCT.CustTypeID = CT.CustTypeID
	JOIN tblReview R ON C.CustomerID = R.CustomerID
	JOIN tblRating RA ON R.RatingID = RA.RatingID
WHERE RA.RatingName = '5 stars' AND CT.CustTypeName = 'Loyal' AND
	C.CustomerID = R.SellerID AND 
	R.SellerID IN (SELECT C.CustomerID
					FROM  tblCustomer C
					JOIN tblOrder ORD ON C.CustomerID = ORD.CustomerID
					JOIN tblLineItem L ON L.OrderID = ORD.OrderID
					JOIN tblOffering O ON L.OfferingID = O.OfferingID
					GROUP BY C.CustomerID
					HAVING SUM(O.Price) > 10000)
GROUP BY C.CustomerID

/*
  _                    _    
 | |                  | |   
 | |__  _ __ ___  __ _| | __
 | '_ \| '__/ _ \/ _` | |/ /
 | |_) | | |  __/ (_| |   < 
 |_.__/|_|  \___|\__,_|_|\_\

*/

-- Start of Josiah's work ->
-- views
-- 1) Average price of each of the top 100 product sold on the platform ordered by most popular product
CREATE VIEW josiahc_vwAvgPriceOfTop100Prod AS
SELECT TOP 100 P.ProductName, PRI.[Average Price]
FROM tblProduct P
	JOIN tblOffering O ON O.ProductID = P.ProductID
	JOIN (SELECT P.ProductID, COUNT(*) AS 'Popularity'
			FROM tblProduct P
				JOIN tblOffering O ON O.ProductID = P.ProductID
			GROUP BY P.ProductID) POP ON POP.ProductID = P.ProductID
	JOIN (SELECT P.ProductID, AVG(O.Price) AS 'Average Price'
			FROM tblProduct P
				JOIN tblOffering O ON O.ProductID = P.ProductID
			GROUP BY P.ProductID) PRI ON PRI.ProductID = P.ProductID
	GROUP BY P.ProductID, P.ProductName, POP.Popularity, PRI.[Average Price]
ORDER BY POP.Popularity DESC

-- 2) Ratio of offerings made to orders placed for each customer who is also a seller, ordered by more offerings made
CREATE VIEW josiahc_vwRatioOfOfferingsToOrders AS
SELECT TOP 100000 C.FirstName, C.LastName, (OFFR.[Offerings Made] / ORD.[Orders Placed]) AS 'Ratio: Offerings - Orders'
FROM tblCustomer C
	JOIN (SELECT C.CustomerID, COUNT(*) AS 'Offerings Made'
			FROM tblCustomer C
				JOIN tblOffering O ON C.CustomerID = O.SellerID
			GROUP BY C.CustomerID) OFFR ON OFFR.CustomerID = C.CustomerID
	JOIN (SELECT C.CustomerID, COUNT(*) AS 'Orders Placed'
			FROM tblCustomer C
				JOIN tblOrder O ON C.CustomerID = O.CustomerID
			GROUP BY C.CustomerID) ORD ON ORD.CustomerID = C.CustomerID
GROUP BY C.CustomerID, C.FirstName, C.LastName, ORD.[Orders Placed], OFFR.[Offerings Made]
ORDER BY (OFFR.[Offerings Made] / ORD.[Orders Placed]) DESC

-- check constraints
-- 1) Two Detail Types cannot have the same name
CREATE FUNCTION josiahc_fnNoDuplicateNames()
RETURNS INT
AS BEGIN
	DECLARE @Ret INT = 0

	IF EXISTS 
		(SELECT DetailTypeName
		FROM tblDetailType
		GROUP BY DetailTypeName
		HAVING COUNT(*) > 1)
	SET @Ret = 1

	RETURN @Ret
END
GO

ALTER TABLE tblDetailType
ADD CONSTRAINT josiahc_ckNoDuplicateNames
CHECK (dbo.josiahc_fnNoDuplicateNames() = 0)
GO

-- 2) An offering cannot have more than one of the same Detail Type
CREATE FUNCTION josiahc_fnNoDuplicateUnitNames()
RETURNS INT
AS BEGIN
	DECLARE @Ret INT = 0

	IF EXISTS 
		(SELECT UnitName
		FROM tblUnit
		GROUP BY UnitName
		HAVING COUNT(*) > 1)
	SET @Ret = 1

	RETURN @Ret
END
GO

ALTER TABLE tblUnit
ADD CONSTRAINT josiahc_ckNoDuplicateUnitNames
CHECK (dbo.josiahc_fnNoDuplicateUnitNames() = 0)
GO

-- computed columns
-- 1) average rating
CREATE FUNCTION josiahc_fnCalcAvgRating(@SellID INT)
RETURNS NUMERIC(3, 1)
AS BEGIN
	DECLARE @Result NUMERIC(3, 1)
	SET @Result = (SELECT AVG(CAST(
		CASE SUBSTRING(R.RatingName, 2, 1)
			WHEN '.' THEN SUBSTRING(R.RatingName, 1, 3) 
			ELSE SUBSTRING(R.RatingName, 1, 1) END
		AS NUMERIC(3, 1)))
		FROM tblRating R
			JOIN tblReview RV ON RV.RatingID = R.RatingID
		WHERE sellerID = @SellID)
	Return @Result
END
GO

ALTER TABLE tblCustomer
ADD AvgRating AS (dbo.josiahc_fnCalcAvgRating(CustomerID))

-- 2) total number of offerings by seller
CREATE FUNCTION josiahc_fnCalcNumOfOfferings(@CustID INT)
RETURNS INT
AS BEGIN
	DECLARE @Result INT
	SET @Result = (SELECT COUNT(*)
		FROM tblCustomer C
			JOIN tblOffering O ON C.CustomerID = O.SellerID
		WHERE C.CustomerID = @CustID)
	RETURN @Result
END
GO

ALTER TABLE tblCustomer
ADD NumOfOfferings AS (dbo.josiahc_fnCalcNumOfOfferings(CustomerID))

-- stored procedures
-- context for sproc 1 {
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
	-- construct and populate temp tables
	CREATE TABLE Temp_Details
		(DetailID INT IDENTITY(1,1) PRIMARY KEY,
		DetailType INT NULL,
		[Detail] [varchar](500) NULL,
		[source_JobURL] [varchar](500) NULL)
	GO

	CREATE TABLE Temp_Products
		(ProductID INT IDENTITY(1,1) PRIMARY KEY,
		ProductName VARCHAR(100),
		ProductTypeID INT,
		ProductDesc VARCHAR(500),
		Price VARCHAR(100))
	GO

	INSERT INTO Temp_Details(DetailType, Detail, source_JobURL)
	SELECT DetailType, Detail, source_JobURL
	FROM WORKING_Details
	GO

	INSERT INTO Temp_Products(ProductTypeID, ProductName, ProductDesc, Price)
	SELECT ProductTypeID, ProductName, ProductDesc, Price
	FROM WORKING_Products
	GO
-- } end context for sproc

-- sproc 1 josiahc
ALTER PROCEDURE josiahc_uspPopScrapedDate
AS

-- product info
DECLARE @ProdTypeID INT
DECLARE @ProdName VARCHAR(100)
DECLARE @ProdDesc VARCHAR(500)

-- detail info
DECLARE @URL VARCHAR(500)
DECLARE @DetTypeID INT
DECLARE @OffID INT
DECLARE @DetDesc VARCHAR(500)
DECLARE @UnitID INT = (SELECT UnitID FROM tblUnit WHERE UnitName = 'none')

-- offering info
DECLARE @SellerID INT
DECLARE @ProdID INT
DECLARE @AddrID INT
DECLARE @Price MONEY
DECLARE @Prices VARCHAR(100)
DECLARE @OffName VARCHAR(50)
DECLARE @OffDesc VARCHAR(2500)
DECLARE @StartDate DATE
DECLARE @EndDate DATE

-- other vars
DECLARE @WorkingDetailID INT
DECLARE @CurrentProdID INT = (SELECT MIN(ProductID) FROM Temp_Products)
DECLARE @MaxProdID INT = (SELECT MAX(ProductID) FROM Temp_Products)

WHILE @CurrentProdID <= @MaxProdID BEGIN
	PRINT @CurrentProdID
	-- prep product vars
	SET @ProdTypeID = (SELECT ProductTypeID FROM Temp_Products WHERE ProductID = @CurrentProdID)
	SET @ProdName = (SELECT ProductName FROM Temp_Products WHERE ProductID = @CurrentProdID)
	SET @ProdDesc = (SELECT ProductDesc FROM Temp_Products WHERE ProductID = @CurrentProdID)

	-- prep offering vars
	SET @SellerID =
		(SELECT TOP(1) C.CustomerID
		FROM tblCustomerType CT
			JOIN tblCustomerCustomerType CCT ON CCT.CustTypeID = CT.CustTypeID
			JOIN tblCustomer C ON C.CustomerID = CCT.CustomerID
		WHERE CT.CustTypeName = 'seller'
			AND CCT.EndDate IS NULL
		ORDER BY NEWID())
	SET @AddrID =
		(SELECT TOP(1) AddressID
		FROM tblAddress
		ORDER BY NEWID())
	SET @OffName = (SELECT 'offering from ' + (SELECT FirstName FROM tblCustomer WHERE CustomerID = @SellerID))
	SET @OffDesc = NULL
	SET @StartDate = (SELECT CAST(DATEADD(day, -CAST(RAND() * 10000 AS INT), GETDATE()) AS DATE))
	SET @EndDate = (SELECT DATEADD(day, CAST(RAND() * 100 AS INT), @StartDate))
	PRINT 'start on prices'
	SET @Prices = (SELECT Price FROM Temp_Products WHERE ProductID = @CurrentProdID)
	IF @Prices <> '' AND @Prices NOT LIKE '%�%'
		SET @Price = (SELECT CAST(SUBSTRING(@Prices, CHARINDEX('$', @Prices, 2), 10) AS MONEY))
	ELSE
		SET @Price = (SELECT CAST(((RAND() * 200) + 1) AS MONEY))
	PRINT 'finish prices'

	-- prep common detail vars
	SET @URL = @ProdDesc

	PRINT 'Begin Trans'
	BEGIN TRAN T1
		-- insert product
		INSERT INTO tblProduct(ProductName, ProductDesc, ProductTypeID)
			VALUES(@ProdName, @ProdDesc, @ProdTypeID)
		IF @@ERROR <> 0
			ROLLBACK TRAN T1
		ELSE
			BEGIN TRAN T2
				-- insert offering
				SET @ProdID = SCOPE_IDENTITY()
				INSERT INTO tblOffering(SellerID, ProductID, AddressID, OfferingName, OfferingDesc, StartDate, EndDate, Price)
					VALUES(@SellerID, @ProdID, @AddrID, @OffName, @OffDesc, @StartDate, @EndDate, @Price)
				IF @@ERROR <> 0
					ROLLBACK TRAN T2
				ELSE
					BEGIN TRAN T3
						-- insert details
						SET @OffID = SCOPE_IDENTITY()

						-- create temprorary table for details attached to product
						SELECT * 
						INTO Ephemeral_Details
						FROM Temp_Details
						WHERE source_JobURL = @URL

						-- check to see if any details exist for the given product, if not, do nothing
						WHILE (SELECT COUNT(*) FROM Ephemeral_Details) > 0 BEGIN
							SET @WorkingDetailID = (SELECT TOP(1) DetailID FROM Ephemeral_Details ORDER BY DetailID ASC)
							SET @DetDesc = (SELECT Detail FROM Ephemeral_Details WHERE DetailID = @WorkingDetailID)
							SET @DetTypeID = CAST((SELECT DetailType FROM Ephemeral_Details WHERE DetailID = @WorkingDetailID) AS INT)

							INSERT INTO tblDetail(OfferingID, DetailTypeID, UnitID, DetailDesc)
								VALUES (@OffID, @DetTypeID, @UnitID, @DetDesc)

							DELETE FROM Ephemeral_Details
							WHERE DetailID = @WorkingDetailID
						END

						-- get rid of temp table
						DROP TABLE Ephemeral_Details
						IF @@ERROR <> 0
							ROLLBACK TRAN T3
						ELSE
						COMMIT TRAN T3
			COMMIT TRAN T2
	COMMIT TRAN T1
	SET @CurrentProdID = @CurrentProdID + 1
END

-- 2) insert unit
CREATE PROCEDURE josiahc_uspInsertUnit
@UnitName VARCHAR(50),
@UnitAbbr VARCHAR(10),
@UnitDesc VARCHAR(500)
AS

BEGIN TRAN T1
	INSERT INTO tblUnit(UnitName, UnitDesc, UnitAbbr)
		VALUES(@UnitName, @UnitDesc, @UnitAbbr)
	IF @@ERROR <> 0
		ROLLBACK TRAN T1
	ELSE
		COMMIT TRAN T1
GO

/*
  _                    _    
 | |                  | |   
 | |__  _ __ ___  __ _| | __
 | '_ \| '__/ _ \/ _` | |/ /
 | |_) | | |  __/ (_| |   < 
 |_.__/|_|  \___|\__,_|_|\_\

*/

-- Joseph Chou
/* Stored procedures */
/* Inserts an order given customer info and order datetime, then returns the newly inserted order ID */
/*CREATE*/ ALTER PROCEDURE jchou8_uspInsertAndReturnOrder
@CustFname varchar(100),
@CustLname varchar(100),
@CustDOB date,
@DateTime datetime,
@ORID INT OUTPUT
AS
DECLARE @CID INT

EXEC emilyd61_uspGetCustID
@Fname = @CustFname,
@Lname = @CustLname,
@Dob = @CustDOB,
@CustID = @CID OUTPUT

IF @CID IS NULL
	BEGIN
	PRINT '@CID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('CustomerID variable @CID cannot be NULL', 11,1)
	RETURN
END

BEGIN TRAN T1

INSERT INTO tblOrder(CustomerID, OrderDateTime)
VALUES (@CID, @DateTime)

IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRAN T1
	END
ELSE 
	BEGIN
		SET @ORID = (SELECT SCOPE_IDENTITY())
		COMMIT TRAN T1
	END
GO

/* Given order ID, seller information, and quantity, inserts a line item. */
ALTER PROCEDURE [dbo].[jchou8_uspInsertLineItemWithID]
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB date,
@OffName varchar(50),
@OffStart DATE,
@ORID INT,
@Quantity INT
AS
DECLARE @OFID INT

IF @ORID IS NULL
	BEGIN
	PRINT '@ORID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('OrderID variable @ORID cannot be NULL', 11,1)
	RETURN
END

EXEC jchou8_uspGetOffering
@SellFname = @SellFname,
@SellLname = @SellLname,
@SellDOB = @SellDOB,
@Name = @OffName,
@Start = @OffStart,
@OffID = @OFID OUTPUT

IF @OFID IS NULL
	BEGIN
	PRINT '@OFID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('OfferingID variable @OFID cannot be NULL', 11,1)
	RETURN
END

BEGIN TRAN T1
INSERT INTO tblLineItem(OrderID, OfferingID, Qty)
VALUES(@ORID, @OFID, @Quantity)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE 
	COMMIT TRAN T1
GO

/* Insert a simulated order with random offerings */
CREATE PROCEDURE jchou8_uspSimulateOrder
@Run INT
AS
DECLARE @CustID INT 
DECLARE @OrderID INT
DECLARE @OfferingID INT

DECLARE @CustFname varchar(100)
DECLARE @CustLname varchar(100)
DECLARE @CustDOB DATE

DECLARE @SellFname varchar(100)
DECLARE @SellLname varchar(100)
DECLARE @SellDOB DATE

DECLARE @NumLineItems INT
DECLARE @Qty INT
DECLARE @OrdDateTime DATETIME

DECLARE @OffName varchar(50)
DECLARE @OffStart DATE

WHILE @Run > 0
BEGIN
	SET @CustID = (SELECT TOP 1 CustomerID FROM tblCustomer ORDER BY NEWID())
	
	SET @CustFname = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @CustID)
	SET @CustLname = (SELECT LastName FROM tblCustomer WHERE CustomerID = @CustID)
	SET @CustDOB = (SELECT DOB FROM tblCustomer WHERE CustomerID = @CustID)

	SET @NumLineItems = RAND() * 5 + 1
	SET @OrdDateTime = CURRENT_TIMESTAMP

	EXEC jchou8_uspInsertAndReturnOrder
	@CustFname = @CustFname,
	@CustLname = @CustLname,
	@CustDOB = @CustDOB,
	@DateTime = @OrdDateTime,
	@ORID = @OrderID OUTPUT

	WHILE @NumLineItems > 0
	BEGIN
		SET @OfferingID = (SELECT TOP 1 OfferingID FROM tblOffering ORDER BY NEWID())

		SET @SellFname = (SELECT C.FirstName FROM tblOffering O JOIN tblCustomer C ON O.SellerID = C.CustomerID WHERE O.OfferingID = @OfferingID)
		SET @SellLname = (SELECT C.LastName FROM tblOffering O JOIN tblCustomer C ON O.SellerID = C.CustomerID WHERE O.OfferingID = @OfferingID)
		SET @SellDOB = (SELECT C.DOB FROM tblOffering O JOIN tblCustomer C ON O.SellerID = C.CustomerID WHERE O.OfferingID = @OfferingID)
		SET @OffName = (SELECT OfferingName FROM tblOFFERING WHERE OfferingID = @OfferingID) 
		SET @OffStart = (SELECT StartDate FROM tblOFFERING WHERE OfferingID = @OfferingID) 
		
		SET @Qty = RAND() * 10 + 1

		EXEC jchou8_uspInsertLineItemWithID
		@SellFname = @SellFname,
		@SellLname = @SellLname,
		@SellDOB = @SellDOB,
		@OffName = @OffName,
		@OffStart = @OffStart,
		@ORID = @OrderID,
		@Quantity = @Qty

		SET @NumLineItems = @NumLineItems - 1
	END

	SET @Run = @Run - 1
END

GO

/* Business rules */
/* Customers cannot review themselves */
CREATE FUNCTION fn_NoSelfReview()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (
	SELECT ReviewID
	FROM tblReview
	WHERE CustomerID = SellerID
)
	SET @Ret = 1
RETURN @Ret
END

GO

ALTER TABLE tblReview
ADD CONSTRAINT CK_NoSelfReview
CHECK (dbo.fn_NoSelfReview() = 0)

GO

/* Only customers with type 'seller' can have offerings */
CREATE FUNCTION fn_OnlySellersOffer()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (
	SELECT O.OfferingID
	FROM tblOffering O
	JOIN tblCustomer C ON C.CustomerID = O.SellerID
	WHERE NOT C.CustomerID IN (
		SELECT C.CustomerID
		FROM tblCustomer C
		JOIN tblCustomerCustomerType CCT ON CCT.CustomerID = C.CustomerID
		JOIN tblCustomerType CT ON CT.CustTypeID = CCT.CustTypeID
		WHERE CT.CustTypeName = 'Seller'
	)
)
	SET @Ret = 1
RETURN @Ret

END

GO

ALTER TABLE tblOffering
ADD CONSTRAINT CK_OnlySellersOffer
CHECK (dbo.fn_OnlySellersOffer() = 0)

GO

/* Computed columns */
/* Line item subtotal */
CREATE FUNCTION fn_LineItemSubtotal(@LineItemID INT)
RETURNS Money
AS
BEGIN
DECLARE @Ret Money
SET @Ret = (SELECT O.Price * LI.Qty
FROM tblLineItem LI
JOIN tblOffering O ON LI.OfferingID = O.OfferingID
WHERE LI.LineItemID = @LineItemID
)
RETURN @Ret
END

GO

ALTER TABLE tblLineItem
ADD Subtotal AS (dbo.fn_LineItemSubtotal(LineItemID))

GO

/* Order total */
CREATE FUNCTION fn_OrderTotal(@OrderID INT)
RETURNS Money
AS
BEGIN
DECLARE @Ret Money
SET @Ret = (SELECT SUM(LI.Subtotal)
FROM tblOrder O
JOIN tblLineItem LI ON LI.OrderID = O.OrderID
WHERE O.OrderID = @OrderID
)
RETURN @Ret
END

GO

ALTER TABLE tblOrder
ADD Total AS (dbo.fn_OrderTotal(OrderID))

GO

/* Views */
/* View the top seller in each state based on total profit made in the past month */
CREATE VIEW jchou8_topSellersPerState AS
SELECT C.CustomerID, C.FirstName, C.LastName, C.PastMonthProfits, S.State
FROM (SELECT DISTINCT State FROM tblAddress) S
CROSS APPLY (
	SELECT TOP 1 C.CustomerID, C.FirstName, C.LastName, C.State, C.PastMonthProfits
	FROM (
		SELECT C.CustomerID, C.FirstName, C.LastName, A.State, SUM(R.Total) AS PastMonthProfits
		FROM tblCustomer C
		JOIN tblOffering O ON O.SellerID = C.CustomerID
		JOIN tblLineItem LI ON LI.OfferingID = O.OfferingID
		JOIN tblOrder R ON R.OrderID = LI.OrderID
		JOIN tblAddress A ON C.AddressID = A.AddressID
		WHERE R.OrderDateTime > (SELECT GetDate() - 31)
		GROUP BY C.FirstName, C.LastName, C.CustomerID, A.State
	) C
	WHERE C.State = S.State
	ORDER BY C.PastMonthProfits DESC
) C

GO

/* View the customers who have purchased from at least 10 different sellers who have also left at least 10 reviews */
CREATE VIEW jchou8_diverseBuyersWith10Reviews AS
SELECT C.CustomerID, C.FirstName, C.LastName,  COUNT(DISTINCT S.CustomerID) AS DistinctSellers
FROM tblCustomer C
JOIN tblOrder R ON R.CustomerID = C.CustomerID
JOIN tblLineItem LI ON LI.OrderID = R.OrderID
JOIN tblOffering O ON O.OfferingID = LI.OfferingID
JOIN tblCustomer S ON O.SellerID = S.CustomerID
WHERE C.CustomerID IN (
	SELECT C.CustomerID
	FROM tblCustomer C
	JOIN tblReview R ON R.CustomerID = C.CustomerID
	GROUP BY C.CustomerID, C.FirstName, C.LastName
	HAVING COUNT(R.ReviewID) >= 10
)
GROUP BY C.CustomerID, C.FirstName, C.LastName
HAVING COUNT(DISTINCT S.CustomerID) >= 10

/*

Ken Long

Each team member must code 2 of each of the following (8 objects per student):

1) Stored procedure

2) Check constraint

3) Computed column

4) Views

As stated in lecture, grading will be based on the student's ability to leverage complex skills presented in lecture and should include the following where appropriate:

* explicit transactions

* Complexity as appropriate: multiple JOINs, GROUP BY, ORDER BY, TOP, RANK, CROSS APPLY

* error-handling

* passing of appropriate  parameters (name values and/or output parameters)

* subqueries

* variables
*/

ALTER /*CREATE*/ PROC long27km_usp_GetLocalOfferingsBySeller
@Zip varchar(20),
@SellerFName varchar(100),
@SellerLName varchar(100),
@Offset int,
@NumResults int
AS
BEGIN
	
	SELECT * 
	FROM tblOffering O
	JOIN tblCustomer S
	ON S.CustomerID = O.SellerID
	JOIN tblCustomerCustomerType CCT
	ON S.CustomerID = CCT.CustomerID
	JOIN tblCustomerType CT
	ON CCT.CustTypeID = CT.CustTypeID
	JOIN tblAddress A
	ON A.AddressID = O.AddressID
	WHERE A.Zip = @Zip
	AND CT.CustTypeName = 'Seller'
	AND S.FirstName = @SellerFName
	AND S.LastName = @SellerLName
	ORDER BY O.StartDate DESC
	OFFSET (@Offset) ROWS
	FETCH NEXT (@NumResults) ROWS ONLY;
END

GO

/*ALTER*/ CREATE PROC long27km_usp_GetMostRecentLocalOfferingsOfProductType
@CustomerFName varchar(100),
@CustomerLName varchar(100),
@DOB DATE,
@ProdTypeName varchar(100),
@Offset int,
@NumResults int
AS
BEGIN

	DECLARE @A_ID INT = (SELECT AddressID FROM tblCustomer C WHERE C.FirstName = @CustomerFName AND C.LastName = @CustomerLName AND C.DOB = @DOB) 

	DECLARE @Zip varchar(20) = (SELECT Zip FROM tblAddress WHERE AddressID = @A_ID)
	
	SELECT * 
	FROM tblOffering O
	JOIN tblAddress A
	ON A.AddressID = O.AddressID
	JOIN tblProduct P
	ON O.ProductID = P.ProductID
	JOIN tblProductType PT
	ON PT.ProductTypeID = P.ProductTypeID
	WHERE A.Zip = @Zip
	AND PT.ProductTypeName LIKE '%'+@ProdTypeName+'%'
	ORDER BY O.StartDate DESC
	OFFSET (@Offset) ROWS
	FETCH NEXT (@NumResults) ROWS ONLY;
END


GO

SELECT TOP 1 * FROM tblCustomer

EXEC long27km_usp_GetMostRecentLocalOfferingsOfProductType @CustomerFName = 'Eloisa', @CustomerLName = 'Durfey', @DOB = '1985-06-20', @ProdTypeName = 'tool', @Offset = 0, @NumResults = 10

GO

CREATE PROC long27km_usp_GetLocalOfferingsForCustomer
@CustomerFName varchar(100),
@CustomerLName varchar(100),
@DOB Date,
@Offset int,
@NumResults int
AS
BEGIN
	
	DECLARE @A_ID INT = (SELECT AddressID FROM tblCustomer C WHERE C.FirstName = @CustomerFName AND C.LastName = @CustomerLName AND C.DOB = @DOB) 

	DECLARE @Zip varchar(20) = (SELECT Zip FROM tblAddress WHERE AddressID = @A_ID)

	SELECT * 
	FROM tblOffering O
	JOIN tblAddress A
	ON A.AddressID = O.AddressID
	WHERE A.Zip = @Zip

END

GO 

SELECT TOP 1 * FROM tblCustomer ORDER BY NEWID()

EXEC long27km_usp_GetLocalOfferingsForCustomer @CustomerFName = 'Lawanda', @CustomerLName = 'Ernesto', @DOB = '1999-12-04', @Offset = 0, @NumResults = 10

SELECT COUNT(*) FROM tblCustomer WHERE LEN(PhoneNumber) < 5

SELECT CAST(CAST((RAND()*899)+100 AS INT) AS CHAR(3))+'-'+CAST(CAST((RAND()*899)+100 AS INT) AS CHAR(3))+'-'+CAST(CAST((RAND()*8999)+1000 AS INT) AS CHAR(4))

DECLARE @MAX_CUST INT = (SELECT MAX(CUSTOMERID) FROM tblCustomer)

UPDATE tblCustomer SET PhoneNumber = SUBSTRING(CAST(CAST((RAND()*CustomerID*899/@MAX_CUST)+100 AS INT) AS VARCHAR(30)), 0, 4)+'-'+SUBSTRING(CAST(CAST((RAND()*CustomerID*899/@MAX_CUST)+100 AS INT) AS VARCHAR(30)), 0, 4)+'-'+SUBSTRING(CAST(CAST((RAND()*CustomerID*8999/@MAX_CUST)+1000 AS INT) AS VARCHAR(30)), 0, 5) WHERE LEN(PhoneNumber) < 10 
/*
 most popular item, avg price for product based on offering, most purchased product by a given customer
 
 Number purchases for a given customer

 */

ALTER /*CREATE*/ VIEW long27km_vwProductStatsByZip AS
SELECT AVG(O.Price) AS AvgPriceInZip, CASE WHEN STDEV(O.Price) IS NULL THEN 0 WHEN STDEV(O.Price) IS NOT NULL THEN STDEV(O.Price) END AS StdDevOfPriceInZip, P.ProductName, A.Zip 
FROM tblOffering O
JOIN tblAddress A
ON O.AddressID = A.AddressID
JOIN tblProduct P
ON P.ProductID = O.ProductID
GROUP BY O.ProductID, P.ProductName, A.Zip

SELECT * FROM long27km_vwProductStatsByZip

CREATE VIEW long27km_vwMostPopularProductByZip AS
SELECT ProductName, NumProdSales, AvgProductPriceForZip, Zip 
FROM 
	(SELECT MAX( ProdCount ) AS NumProdSales, ProductID, Zip FROM
		(SELECT COUNT(P.ProductID) AS ProdCount, P.ProductID, A.Zip 
		FROM tblProduct P 
		JOIN tblOffering O 
		ON P.ProductID = O.ProductID
		JOIN tblAddress A
		ON O.AddressID = A.AddressID
		JOIN tblLineItem LI
		ON LI.OfferingID = O.OfferingID
		GROUP BY A.Zip, P.ProductID) SQ_ProdCount
		GROUP BY Zip, ProductID) SQ_MostPop
JOIN tblOffering O
ON O.ProductID = SQ_MostPop.ProductID
JOIN tblProduct P
ON P.ProductID = SQ_MostPop.ProductID 


GO

SELECT COUNT(P.ProductID) AS ProdCount, P.ProductID, A.Zip 
		FROM tblProduct P 
		JOIN tblOffering O 
		ON P.ProductID = O.ProductID
		JOIN tblAddress A
		ON O.AddressID = A.AddressID
		JOIN tblLineItem LI
		ON LI.OfferingID = O.OfferingID
		GROUP BY A.Zip, P.ProductID

GO

CREATE FUNCTION long27km_fnNumberPurchases(@CustID INT)
RETURNS INT
AS
BEGIN
	DECLARE @TotalNumPurchases INT = 
	(SELECT COUNT(O.OrderID)
	FROM tblOrder O
	WHERE O.CustomerID = @CustID)

	RETURN @TotalNumPurchases

ALTER TABLE tblCustomer
ADD NumPurchases AS (dbo.long27km_fnNumberPurchases(CustomerID))

GO

/*DROP FUNCTION long27km_fnAvgProdPrice*/

ALTER /*CREATE*/ FUNCTION long27km_fnAvgProdPriceForZip(@OfferingID INT)
RETURNS MONEY
AS
BEGIN

	DECLARE @Zip varchar(20) = (SELECT Zip FROM tblAddress A JOIN tblOffering O ON A.AddressID = O.AddressID AND O.OfferingID = @OfferingID)
	DECLARE @ProductID INT = (SELECT ProductID FROM tblOffering WHERE OfferingID = @OfferingID)

	DECLARE @AvgProdPrice MONEY = 
	(SELECT AVG(O.Price)
	FROM tblOffering O
	JOIN tblAddress A
	ON O.AddressID = A.AddressID
	WHERE O.ProductID = @ProductID
	AND A.Zip = @Zip)

	RETURN @AvgProdPrice

/*ALTER TABLE tblOffering
DROP COLUMN AvgProductPriceForZip
*/

ALTER TABLE tblOffering
ADD AvgProductPriceForZip AS (dbo.long27km_fnAvgProdPriceForZip(OfferingID))

SELECT TOP 10 * FROM tblOffering O WHERE O.Price != O.AvgProductPriceForZip


GO

SELECT * FROM tblProductType

/*DROP FUNCTION long27km_OnlyBuyLocally*/

CREATE FUNCTION long27km_OnlyBuyGreensLocally()
RETURNS INT
AS
BEGIN

	DECLARE @RESULT INT = 0

	IF EXISTS (SELECT * 
		FROM tblLineItem LI 
		JOIN tblOffering O
		ON LI.OfferingID = O.OfferingID
		JOIN tblAddress A
		ON A.AddressID = O.AddressID
		JOIN tblOrder ORD
		ON LI.OrderID = ORD.OrderID
		JOIN tblCustomer C
		ON C.CustomerID = ORD.CustomerID
		JOIN tblAddress A2
		ON A2.AddressID = C.AddressID
		JOIN tblProduct P
		ON P.ProductID = O.ProductID
		JOIN tblProductType PT
		ON P.ProductTypeID = PT.ProductTypeID
		WHERE A2.Zip != A.Zip
		AND (PT.ProductTypeName LIKE '%greens%'
		OR PT.ProductTypeName LIKE '%pome%'
		OR PT.ProductTypeName Like '%berry%'))
		
		SET @RESULT = 1


	RETURN @RESULT
END

ALTER TABLE tblLineItem WITH NOCHECK
ADD CONSTRAINT long27km_ckLocalBuyGreens
CHECK (dbo.long27km_OnlyBuyGreensLocally()=0)

/*ALTER TABLE tblLineItem
DROP CONSTRAINT long27km_ckLocalBuy*/


EXEC jchou8_uspSimulateOrder @Run = 1

SELECT * FROM tblDetailType

CREATE FUNCTION long27km_OnlyBuyAsManyAsAvailable()
RETURNS INT
AS
BEGIN

	DECLARE @RESULT INT = 0

	IF (SELECT SUM(LI.Qty) 
		FROM tblLineItem LI 
		JOIN tblOffering O
		ON LI.OfferingID = O.OfferingID)
		> 
		( SELECT DetailDesc 
			FROM tblDetail D
			JOIN tblDetailType DT
			ON D.DetailTypeID = DT.DetailTypeID
			WHERE DT.DetailTypeName='Quantity') 
		
		SET @RESULT = 1


	RETURN @RESULT
END

ALTER TABLE tblLineItem WITH NOCHECK
ADD CONSTRAINT long27km_ckOnlyAvailable
CHECK (dbo.long27km_OnlyBuyAsManyAsAvailable()=0)

SELECT * FROM (SELECT O.OfferingID, CASE WHEN TRY_CONVERT(INT, DetailDesc) IS NOT NULL THEN CAST(DetailDesc AS INT) ELSE 0 END AS Qty, DetailTypeName from tblOffering O join tblDetail D on O.OfferingID = D.OfferingID JOIN tblDetailType DT ON D.DetailTypeID = DT.DetailTypeID WHERE DT.DetailTypeName = 'Quantity') SQ WHERE SQ.Qty < 5

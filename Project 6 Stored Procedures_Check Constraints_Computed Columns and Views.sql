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
@DTime DATETIME
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
 COMMIT TRAN G1

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
	IF @Prices <> '' AND @Prices NOT LIKE '%¢%'
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
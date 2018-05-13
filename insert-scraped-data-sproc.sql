USE GREEN_THUMB
GO

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

-- begin sproc
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

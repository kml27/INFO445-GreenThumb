INSERT INTO tblRating (RatingName)
VALUES ('0.5 stars'), 
('1 star'), 
('1.5 stars'), 
('2 stars'), 
('2.5 stars'), 
('3 stars'),
('3.5 stars'),
('4 stars'),
('4.5 stars'),
('5 stars')

GO

/*CREATE*/ ALTER PROCEDURE jchou8_uspInsertOfferingWrapper
@Run INT
AS
DECLARE @SellID INT 
DECLARE @ProdID INT
DECLARE @AddressID INT

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

GO

EXEC jchou8_uspInsertOfferingWrapper
@Run = 5000

GO

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

EXEC jchou8_uspSimulateOrder
@Run = 5000
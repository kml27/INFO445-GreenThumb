/* Stored procedures */
/* Inserts an order given customer info and order datetime, then returns the newly inserted order ID */
CREATE PROCEDURE jchou8_uspInsertAndReturnOrder
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
	ROLLBACK TRAN T1
ELSE 
	SET @ORID = (SELECT SCOPE_IDENTITY())
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
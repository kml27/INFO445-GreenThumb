/* Insert a review given customer info, seller info, rating, review title, and review text. */
CREATE PROCEDURE jchou8_uspInsertReview
@CustFname varchar(100),
@CustLname varchar(100),
@CustDOB date,
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB date,
@RateName varchar(10),
@Title varchar(50),
@Text varchar(1000)
AS
DECLARE @CID INT
DECLARE @SID INT
DECLARE @RID INT

/* Need GetCustomer stored procedure

EXEC emilyd61_uspGetCustID
@??? = @CustFname
@??? = @CustLname
@??? = @CustDOB
@??? = @CID OUTPUT */

IF @CID IS NULL
	BEGIN
	PRINT '@CID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('CustomerID variable @CID cannot be NULL', 11,1)
	RETURN
END

/*
EXEC emilyd61_uspGetCustID
@??? = @SellFname
@??? = @SellLname
@??? = @SellDOB
@??? = @SID OUTPUT
*/

IF @SID IS NULL
	BEGIN
	PRINT '@SID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('SellerID variable @SID cannot be NULL', 11,1)
	RETURN
END

IF @CID = @SID
	BEGIN
	PRINT '@CID and @SID are equal; process terminated'
	RAISERROR ('SellerID and CustomerID cannot be the same; sellers cannot review themselves', 11,50001)
	RETURN
END

EXEC josiahc_uspGetRatingID
@ratingName = @RateName,
@ratingID = @RID OUTPUT

IF @RID IS NULL
	BEGIN
	PRINT '@RID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('RatingID variable @RID cannot be NULL', 11,1)
	RETURN
END

BEGIN TRAN T1
INSERT INTO tblReview (CustomerID, SellerID, RatingID, ReviewTitle, ReviewText)
VALUES (@CID, @SID, @RID, @Title, @Text)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE 
	COMMIT TRAN T1

GO

/* Insert a rating given a rating name and description */
CREATE PROCEDURE jchou8_uspInsertRating
@Name varchar(10),
@Desc varchar(50) = NULL
AS
BEGIN TRAN T1
INSERT INTO tblRating (RatingName, RatingDesc)
VALUES (@Name, @Desc)
COMMIT TRAN T1

GO

/* Inserts an order given customer info and order datetime */
CREATE PROCEDURE jchou8_uspInsertOrder
@CustFname varchar(100),
@CustLname varchar(100),
@CustDOB date,
@DateTime datetime
AS
DECLARE @CID INT
/* Need GetCustomer stored procedure

EXEC emilyd61_uspGetCustID
@??? = @CustFname
@??? = @CustLname
@??? = @CustDOB
@??? = @CID OUTPUT
*/

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
	COMMIT TRAN T1

GO

/* Given customer information, order datetime, seller information, quantity, */
CREATE PROCEDURE jchou8_uspInsertLineItem
@CustFname varchar(100),
@CustLname varchar(100),
@CustDOB date,
@DateTime datetime,
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB date,
@ProdName varchar(100),
@OffName varchar(50),
@OffStart DATE,
@OffEnd DATE,
@Quantity INT
AS
DECLARE @ORID INT
DECLARE @OFID INT

/* Need GetOrder stored procedure

EXEC long27km_uspGetOrderID
@??? = @CustFname
@??? = @CustLname
@??? = @CustDOB
@??? = @DateTime
@??? = @ORID OUTPUT
*/

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

/* Inserts an offering with given seller information, product information, street address, zipcode, 
offering price, name, description, start date, and end date. */
CREATE PROCEDURE jchou8_uspInsertOffering
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB date,
@ProdName varchar(100),
@StAddress varchar(100),
@Zip INT,
@Price money,
@Name varchar(50),
@Desc varchar(2500) = NULL,
@Start DATE,
@End DATE = NULL
AS
DECLARE @SID INT
DECLARE @PID INT
DECLARE @AID INT
/* Need GetCustomer stored procedure

EXEC emilyd61_uspGetCustID
@??? = @SellFname
@??? = @SellLname
@??? = @SellDOB
@??? = @SID OUTPUT */

IF @SID IS NULL
	BEGIN
	PRINT '@SID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('SellerID variable @SID cannot be NULL', 11,1)
	RETURN
END

/*
Need GetProduct stored procedure
EXEC emilyd61_uspGetProdID
@??? = @ProdName
@??? = @PID OUTPUT
*/

IF @PID IS NULL
	BEGIN
	PRINT '@PID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('ProductID variable @PID cannot be NULL', 11,1)
	RETURN
END

EXEC emilyd61_uspGetAddressID
@Street = @StAddress,
@Zipcode = @Zip,
@Add_ID = @AID OUTPUT

IF @AID IS NULL
	BEGIN
	PRINT '@AID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('AddressID variable @AID cannot be NULL', 11,1)
	RETURN
END

BEGIN TRAN T1
INSERT INTO tblOffering(SellerID, ProductID, AddressID, Price, OfferingName, OfferingDesc, StartDate, EndDate)
VALUES(@SID, @PID, @AID, @Price, @Name, @Desc, @Start, @End)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE 
	COMMIT TRAN T1

GO


/* Inserts an offering with given seller information, product information, street address, zipcode, 
offering price, name, description, start date, and end date. */
CREATE PROCEDURE jchou8_uspGetOffering
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB date,
@Name varchar(50),
@Start DATE,
@OffID INT OUTPUT
AS
DECLARE @SID INT
DECLARE @PID INT

/* Need GetCustomer stored procedure
EXEC emilyd61_uspGetCustID
@??? = @SellFname
@??? = @SellLname
@??? = @SellDOB
@??? = @SID OUTPUT
*/

SET @OffID = (
	SELECT OfferingID FROM tblOffering 
	WHERE SellerID = @SID
	AND OfferingName = @Name
	AND StartDate = @Start
)
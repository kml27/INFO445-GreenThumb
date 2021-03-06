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

EXEC emilyd61_uspGetCustID
@Fname = @SellFname,
@Lname = @SellLname,
@Dob = @SellDOB,
@CustID = @SID OUTPUT

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
	COMMIT TRAN T1

GO


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

/* Given customer information, order datetime, seller information, and quantity, inserts a line item. */
CREATE PROCEDURE jchou8_uspInsertLineItem
@CustFname varchar(100),
@CustLname varchar(100),
@CustDOB date,
@DateTime datetime,
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB date,
@OffName varchar(50),
@OffStart DATE,
@Quantity INT
AS
DECLARE @ORID INT
DECLARE @OFID INT

EXEC long27km_GetOrderID
@FName = @CustFname,
@Lname = @CustLname,
@DOB = @CustDOB,
@OrderDateTime = @DateTime,
@OrderID = @ORID OUTPUT

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


/* Given order ID, seller information, and quantity, inserts a line item. */
CREATE PROCEDURE jchou8_uspInsertLineItemWithID
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

/* Inserts an offering with given seller information, product information, street address, zipcode, 
offering price, name, description, start date, and end date. */
CREATE PROCEDURE jchou8_uspInsertOffering
@SellFname varchar(100),
@SellLname varchar(100),
@SellDOB date,
@ProdName varchar(100),
@AddSt varchar(100),
@AddCity varchar(100),
@AddState varchar(100),
@AddZip INT,
@Price money,
@Name varchar(50),
@Desc varchar(2500) = NULL,
@Start DATE,
@End DATE = NULL
AS
DECLARE @SID INT
DECLARE @PID INT
DECLARE @AID INT

EXEC emilyd61_uspGetCustID
@Fname = @SellFname,
@Lname = @SellLname,
@Dob = @SellDOB,
@CustID = @SID OUTPUT

IF @SID IS NULL
	BEGIN
	PRINT '@SID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('SellerID variable @SID cannot be NULL', 11,1)
	RETURN
END

EXEC emilyd61_uspGetProdID
@ProdName = @ProdName,
@ProdID = @PID OUTPUT

IF @PID IS NULL
	BEGIN
	PRINT '@PID IS NULL and will fail on insert statement; process terminated'
	RAISERROR ('ProductID variable @PID cannot be NULL', 11,1)
	RETURN
END

EXEC emilyd61_uspGetAddressID
@Street = @AddSt,
@City = @AddCity,
@State = @AddState,
@Zipcode = @AddZip,
@Address_ID = @AID OUTPUT

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


/* Gets an offering ID given seller info, offering name, and start date. */
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

EXEC emilyd61_uspGetCustID
@Fname = @SellFname,
@Lname = @SellLname,
@Dob = @SellDOB,
@CustID = @SID OUTPUT

SET @OffID = (
	SELECT OfferingID FROM tblOffering 
	WHERE SellerID = @SID
	AND OfferingName = @Name
	AND StartDate = @Start
)
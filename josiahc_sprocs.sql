USE GREEN_THUMB
GO

CREATE PROCEDURE josiahc_uspGetDetailTypeID
@typeName VARCHAR(50),
@detailTypeID INT OUTPUT
AS
SET @detailTypeID = (SELECT DetailTypeID FROM tblDetailType WHERE DetailTypeName = @typeName)
IF @detailTypeID IS NULL
BEGIN
	RAISERROR('the specified detailType does not exist', 11, 1)
	RETURN
END
GO

CREATE PROCEDURE josiahc_uspGetUnitID
@unitName VARCHAR(50),
@unitID INT OUTPUT
AS
SET @unitID = (SELECT UnitID FROM tblUnit WHERE UnitName = @unitName)
IF @unitID IS NULL
BEGIN
	RAISERROR('the specified unit does not exist', 11, 1)
	RETURN
END
GO

CREATE PROCEDURE josiahc_uspGetRatingID
@ratingName VARCHAR(50),
@ratingID INT OUTPUT
AS
SET @ratingID = (SELECT RatingID FROM tblRating WHERE RatingName = @ratingName)
IF @ratingID IS NULL
BEGIN
	RAISERROR('the specified rating does not exist', 11, 1)
	RETURN
END
GO

CREATE PROCEDURE jchou8_uspGetCustTypeID
@TypeName varchar(250),
@CTID INT OUTPUT
AS
SET @CTID = (SELECT CustTypeID FROM tblCustomerType WHERE CustTypeName = @TypeName)
IF @CTID IS NULL
BEGIN
	RAISERROR('The specified customer type does not exist.', 11, 1)
	RETURN
END
GO

USE GREEN_THUMB
GO

ALTER PROCEDURE josiahc_uspInsertDetailType
@name VARCHAR(50),
@desc VARCHAR(500),
@sellFname VARCHAR(100),
@sellLname VARCHAR(100),
@sellDOB DATE,
@offeringName VARCHAR(50),
@offeringStart DATE
AS
IF @name IS NULL BEGIN
	RAISERROR('DetailTypeName (@name) cannot be null', 11, 1)
	RETURN
END

BEGIN TRAN T1
	INSERT INTO tblDetailType(DetailTypeName, DetailTypeDesc)
		VALUES(@name, @desc)
	IF @@ERROR <> 0
		ROLLBACK TRAN T1
	ELSE
		COMMIT TRAN T1
GO

CREATE PROCEDURE josiahc_uspInsertDetail
@detailTypeName VARCHAR(50),
@unit VARCHAR(500),
@detailDesc VARCHAR(500)
AS
IF @detailDesc IS NULL BEGIN
	RAISERROR('DetailDesc (@detailDesc) cannot be null', 11, 1)
	RETURN
END

DECLARE @DTID INT
DECLARE @OID INT
DECLARE @UID INT

EXEC josiahc_uspGetDetailTypeID
@typeName = @detailTypeName,
@detailTypeID = @DTID OUTPUT
IF @DTID IS NULL BEGIN
	RAISERROR ('Could not find that detail type', 11,1)
	RETURN
END

EXEC josiahc_uspGetUnitID
@unitName = @unit,
@unitID = @UID OUTPUT
IF @UID IS NULL BEGIN
	RAISERROR ('Could not find that unit', 11,1)
	RETURN
END

EXEC jchou8_uspGetOffering
@SellFname = @sellFName,
@SellLname = @sellLname,
@SellDOB = @sellDOB,
@Name = @offeringName,
@Start = @offeringStart,
@OffID = @OID OUTPUT

BEGIN TRAN T1
	INSERT INTO tblDetail(DetailTypeID, OfferingID, UnitID, DetailDesc)
		VALUES(@DTID, @OID, @UID, @detailDesc)
	IF @@ERROR <> 0
		ROLLBACK TRAN T1
	ELSE
		COMMIT TRAN T1
GO

-- More stored procedure
CREATE PROCEDURE emilyd61_uspGetCustID
@Fname varchar(50),
@Lname varchar(50),
@Dob DATE,
@CustID INT OUTPUT
AS
SET @CustID = (SELECT CustomerID FROM tblCustomer WHERE FirstName = @Fname AND LastName = @Lname AND DOB = @Dob)
IF @CustID is null
BEGIN
	RAISERROR('@CustID cannot be NULL!!!', 11, 1)
	RETURN
END
GO

CREATE PROCEDURE emilyd61_uspGetReviewID
@ReTitle varchar(100),
@ReID INT OUTPUT
AS
SET @ReID = (SELECT ReviewID FROM tblReview WHERE ReviewTitle = @ReTitle)

DECLARE @CustID INT
DECLARE @RateID INT

SET @CustID = (SELECT CustomerID FROM tblCustomer)
SET @RateID = (SELECT RatingID FROM tblRating)

IF @ReID is null
BEGIN
	RAISERROR('@ReID cannot be NULL!!!', 11, 1)
	RETURN
END

CREATE PROCEDURE emilyd61_uspGetProdID
@ProdName varchar(100),
@ProdID INT OUTPUT
AS
SET @ProdID = (SELECT ProductID FROM tblProduct WHERE ProductName = @ProdName)

DECLARE @ProdTypeID INT = (SELECT ProductTypeID FROM tblProductType)

IF @ProdID is null
BEGIN
	RAISERROR('@ProdID cannot be NULL!!!', 11, 1)
	RETURN
END

ALTER PROC emilyd61_uspGetAddressID
@Street varchar (100),
@City varchar (100),
@State varchar (100),
@Zipcode int,
@Address_ID int OUTPUT
AS
SET @Address_ID = (SELECT AddressID FROM tblAddress 
				WHERE StreetAddress = @Street AND City = @City AND [State] = @State AND Zip = @Zipcode)
IF @Address_ID IS NULL
BEGIN PRINT '@Add_ID cannot be null. ERROR.'
	RAISERROR ('@Add_ID is unique key, it cannot be null.',11,1)
	RETURN
	END
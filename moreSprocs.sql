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
@desc VARCHAR(500)
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

-- get offeringID goes here

BEGIN TRAN T1
	INSERT INTO tblDetail(DetailTypeID, OfferingID, UnitID, DetailDesc)
		VALUES(@DTID, @OID, @UID, @detailDesc)
	IF @@ERROR <> 0
		ROLLBACK TRAN T1
	ELSE
		COMMIT TRAN T1
GO
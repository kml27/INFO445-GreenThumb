USE GREEN_THUMB
GO

CREATE PROCEDURE josiahc_uspGetDetailTypeID
@typeName VARCHAR(50),
@detailTypeID INT OUTPUT
AS
SET @detailTypeID = (SELECT DetailTypeID FROM tblDetailType WHERE DetailTypeName = @typeName)

GO

CREATE PROCEDURE josiahc_uspGetUnitID
@unitName VARCHAR(50),
@unitID INT OUTPUT
AS
SET @unitID = (SELECT UnitID FROM tblUnit WHERE UnitName = @unitName)

GO

CREATE PROCEDURE josiahc_uspGetRatingID
@ratingName VARCHAR(50),
@ratingID INT OUTPUT
AS
SET @ratingID = (SELECT RatingID FROM tblRating WHERE RatingName = @ratingName)

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

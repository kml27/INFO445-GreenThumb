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

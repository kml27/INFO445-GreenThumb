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
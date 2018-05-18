USE GREEN_THUMB
Go

-- create inner usp
CREATE PROCEDURE josiahc_uspInsertDetail
@detailTypeName VARCHAR(50),
@unit VARCHAR(500),
@detailDesc VARCHAR(500),
@sellFname VARCHAR(500),
@sellLname VARCHAR(500),
@sellDOB VARCHAR(500),
@offeringName VARCHAR(500),
@offeringStart VARCHAR(500)
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
IF @OID IS NULL BEGIN
	RAISERROR ('Could not find that offering', 11,1)
	RETURN
END


BEGIN TRAN T1
	INSERT INTO tblDetail(DetailTypeID, OfferingID, UnitID, DetailDesc)
		VALUES(@DTID, @OID, @UID, @detailDesc)
	IF @@ERROR <> 0
		ROLLBACK TRAN T1
	ELSE
		COMMIT TRAN T1
GO

-- create wrapper
CREATE PROCEDURE josiahc_uspSyntheticDetail
@numberOfTimes INT
AS

DECLARE @detailTypeNameSynth VARCHAR(50)
DECLARE @unitSynth VARCHAR(500)
DECLARE @detailDescSynth VARCHAR(500)
DECLARE @sellFnameSynth VARCHAR(500)
DECLARE @sellLnameSynth VARCHAR(500)
DECLARE @sellDOBSynth VARCHAR(500)
DECLARE @offeringNameSynth VARCHAR(500)
DECLARE @offeringStartSynth VARCHAR(500)
DECLARE @randID INT
DECLARE @randDT INT

WHILE @numberOfTimes > 0 BEGIN
	WHILE @offeringNameSynth IS NULL BEGIN
		SET @randID = CAST((SELECT RAND() * (SELECT MAX(OfferingID) FROM tblOffering) + 1) AS INT)
		SET @offeringNameSynth = (SELECT OfferingName FROM tblOffering WHERE OfferingID = @randID)
	END
	SET @offeringStartSynth = (SELECT StartDate FROM tblOffering WHERE OfferingID = @randID)
	SET @sellFnameSynth = (SELECT C.FirstName FROM tblOffering O JOIN tblCustomer C ON C.CustomerID = O.SellerID WHERE OfferingID = @randID)
	SET @sellLnameSynth = (SELECT C.LastName FROM tblOffering O JOIN tblCustomer C ON C.CustomerID = O.SellerID WHERE OfferingID = @randID)
	SET @sellDOBSynth = (SELECT C.DOB FROM tblOffering O JOIN tblCustomer C ON C.CustomerID = O.SellerID WHERE OfferingID = @randID)

	SET @randDT = CAST((SELECT RAND() * (SELECT MAX(DetailTypeID) FROM tblDetailType WHERE DetailTypeDesc IS NOT NULL) + 1) AS INT)
	SET @detailTypeNameSynth = (SELECT DetailTypeName FROM tblDetailType WHERE DetailTypeID = @randDT)
	SET @unitSynth = 
		(CASE @detailTypeNameSynth
			WHEN 'color'
				THEN 'none'
			WHEN 'leaf size'
				THEN 'centimetre'
			WHEN 'stalk width'
				THEN 'milimetre'
			WHEN 'leaf density'
				THEN 'square centimeter'
			WHEN 'weight'
				THEN 'kilogram'
			WHEN 'length'
				THEN 'centimetre'
			WHEN 'height'
				THEN 'centimetre'
			WHEN 'width'
				THEN 'centimetre'
			WHEN 'volume'
				THEN 'square centimeter'
			WHEN 'soil pH'
				THEN 'potential of hydrogen'
			WHEN 'stalk color'
				THEN 'none'
		END)
	SET @detailDescSynth = (SELECT RAND() * 99 + 1)
	
	EXECUTE josiahc_uspInsertDetail
		@detailTypeName = @detailTypeNameSynth,
		@unit = @unitSynth,
		@detailDesc = @detailDescSynth,
		@sellFname = @sellFnameSynth,
		@sellLname = @sellLnameSynth,
		@sellDOB = @sellDOBSynth,
		@offeringName = @offeringNameSynth,
		@offeringStart = @offeringStartSynth

	SET @numberOfTimes = @numberOfTimes - 1
END
GO
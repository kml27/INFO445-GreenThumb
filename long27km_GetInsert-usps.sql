USE GREEN_THUMB;

GO

CREATE PROC long27km_wrapper_emilyd61_uspGetCustTypeID 
@CTName varchar(50),
@wT_ID INT OUTPUT
AS BEGIN 

	EXEC emilyd61_uspGetCustTypeID @CustTypeName = @CTName, @CustTypeDescr='', @CustTID = @wT_ID OUTPUT

END

go

CREATE PROC long27km_InsertCustomerCustType
@FName varchar(50),
@LName varchar(50),
@DOB varchar(50),
@Type varchar(50),
@StartDate Date = NULL
AS
BEGIN
	DECLARE @C_ID INT
	DECLARE @T_ID INT

	IF @StartDate IS NULL
	BEGIN
		SET @StartDate = GetDate()
	END

	EXEC emilyd61_uspGetCustID @Fname = @FName, @Lname=@LName, @Dob=@DOB, @CustID = @C_ID OUTPUT

	IF @C_ID IS NULL
	BEGIN
		RAISERROR ('Did not find customer with provided information', 11, 1)
		RETURN
	END
	
	EXEC long27km_wrapper_emilyd61_uspGetCustTypeID @CTName = @Type, @wT_ID = @T_ID OUTPUT 

	IF @T_ID IS NULL
	BEGIN
		RAISERROR ('Did not find customer type with that name', 11, 1)
		RETURN
	END

	BEGIN TRAN T1

		INSERT INTO tblCustomerCustomerType (CustomerID, CustTypeID, StartDate) VALUES (@C_ID, @T_ID, @StartDate)
		 
	IF @@ERROR <> 0
		ROLLBACK TRAN T1
	ELSE
		COMMIT TRAN T1
END

GO

CREATE PROC long27km_GetOrderID
@FName VARCHAR(50),
@Lname VARCHAR(50),
@DOB DATE,
@OrderDateTime DATETIME,
@OrderID INT OUTPUT
AS
BEGIN

	DECLARE @C_ID INT

	EXEC emilyd61_uspGetCustID @Fname = @FName, @Lname = @LName, @Dob=@DOB, @CustID = @C_ID OUTPUT

	IF @C_ID IS NULL
	BEGIN
		RAISERROR ('Did not find customer with the information thar was provided', 11, 1)
		RETURN
	END

	SET @OrderID = (SELECT OrderID FROM tblOrder WHERE CustomerID = @C_ID AND OrderDateTime = @OrderDateTime)

END
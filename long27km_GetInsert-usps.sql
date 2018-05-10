USE GREEN_THUMB;

GO

ALTER /*CREATE*/ PROC long27km_InsertProduct
@ProductTypeName varchar(50),
@ProductName varchar(50),
@ProductDesc varchar(50)
AS
BEGIN
	DECLARE @P_ID INT;

	EXEC emilyd61_uspGetProductTypeID @ProdTypeName = @ProductTypeName, @ProdTypeID = @P_ID OUTPUT;

	IF @P_ID IS NULL
	BEGIN
		RAISERROR ('ProductTypeID not found!', 11, 1);
		RETURN
	END

	BEGIN TRAN

	INSERT INTO tblProduct (ProductName, ProductDesc, ProductTypeID) VALUES (@ProductName, @ProductDesc, @P_ID);
	
	IF @@ERROR <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
END

GO

CREATE TABLE WorkingProduct(
	ProductID INT PRIMARY KEY IDENTITY(1,1),
	ProductName varchar(100),
	ProductDesc varchar(100)
)

DELETE FROM WorkingProduct;

INSERT INTO WorkingProduct (ProductName, ProductDesc) SELECT ProductName, ProductDescr 
	FROM RAW_PRODUCT;


SELECT * FROM WorkingProduct;

DECLARE @ROW_COUNT INT = (SELECT COUNT(*) FROM WorkingPRODUCT);

WHILE @ROW_COUNT > 0
BEGIN

	DECLARE @TYPE INT = (SELECT (RAND()-0.0001)*10);
	
	DECLARE @TYPE_NAME varchar(50) = (SELECT CASE 
		WHEN @TYPE < 3 THEN 'Plant' 
		WHEN @TYPE > 6 THEN 'Seed'
		ELSE
			'Greens'
		END)

	PRINT @TYPE_NAME

	DECLARE @P_ID INT = (SELECT MIN(ProductID) FROM WorkingProduct)

	DECLARE @ProductName varchar(100) = (SELECT ProductName FROM WorkingProduct WHERE ProductID = @P_ID);

	DECLARE @ProductDesc varchar(100) = (SELECT ProductDesc FROM WorkingProduct WHERE ProductID = @P_ID);

	EXEC long27km_InsertProduct @ProductTypeName = @TYPE_NAME, @ProductName = @ProductName, @ProductDesc = @ProductDesc

	DELETE FROM WorkingProduct WHERE ProductID = @P_ID;

	SET @ROW_COUNT = @ROW_COUNT - 1;
END


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
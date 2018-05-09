DECLARE @ROW_COUNT INT = 10000 

WHILE @ROW_COUNT > 0
BEGIN
	
	DECLARE @NUM_Review INT = (SELECT COUNT(*) FROM tblCustomer)
	DECLARE @CustRow [dbo].[typeTableCustRow]
	DECLARE @CustID INT = (SELECT MIN(CustomerID) + RAND() * @NUM_Review FROM tblCustomer)
	DECLARE @SellID INT = (SELECT MIN(CustomerID) + RAND() * @NUM_Review FROM tblCustomer)
	DECLARE @RateID INT = (SELECT MIN(RatingID) + RAND() * @NUM_Review FROM tblRating )

	DECLARE @CustF varchar(150) = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @CustID)
	DECLARE @CustL varchar(150) = (SELECT LastName FROM tblCustomer WHERE CustomerID = @CustID)
	DECLARE @C_DOB date = (SELECT DOB FROM tblCustomer WHERE CustomerID = @CustID)
	DECLARE @SellF varchar(150) = (SELECT FirstName FROM tblCustomer WHERE CustomerID = @SellID)
	DECLARE @SellL varchar(150) = (SELECT LastName FROM tblCustomer WHERE CustomerID = @SellID)
	DECLARE @S_DOB date = (SELECT DOB FROM tblCustomer WHERE CustomerID = @CustID)
	DECLARE @RName varchar(50) = (SELECT RatingName FROM tblRating WHERE RatingID = @RateID)

	DECLARE @ViewName varchar(250) = (SELECT TOP 1 Title FROM RAW_REVIEW ORDER BY NEWID())
	DECLARE @ViewDetail varchar(250) = (SELECT TOP 1 [Text] FROM RAW_REVIEW ORDER BY NEWID()) 

	EXEC jchou8_uspInsertReview 
	@CustFname = @CustF,
	@CustLname = @CustL,
	@CustDOB = @C_DOB,
	@SellFname = @SellF,
	@SellLname = @SellL,
	@SellDOB = @S_DOB,
	@RateName = @RName,
	@Title = @ViewName,
	@Text = @ViewDetail

	SET @ROW_COUNT = @ROW_COUNT - 1
END
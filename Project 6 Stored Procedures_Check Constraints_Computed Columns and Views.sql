/*Project 6: Stored Procedures, Check Constraints, Computed Columns and Views */
USE GREEN_THUMB
GO
/*1) Stored procedure*/
-- Emily Ding
-- insert an order by get the exist CustomerID
CREATE PROCEDURE emilyd61_populateOrder
@F_Name varchar(50),
@L_Name varchar(50),
@D_OB DATE,
@DTime DATETIME,
@Total INT
AS
DECLARE @CID INT

EXEC emilyd61_uspGetCustID
@Fname = @F_Name,
@Lname = @L_Name,
@Dob = @D_OB,
@CustID = @CID OUTPUT

IF @CID IS NULL
 BEGIN
 PRINT '@CID is NULL and this is not good'
 RAISERROR ('CustomerID populating @CID was not found', 11,1)
 RETURN 
 END

BEGIN TRAN G1
INSERT INTO tblORDER (CustomerID, [DateTime], Total)
VALUES (@CID, @DTime, @Total)

IF @@ERROR <> 0
 ROLLBACK TRAN G1
ELSE
 COMMIT TRAN G1

-- Insert customer information from RAW_DATA which converted as WorkingCustomerData
CREATE PROCEDURE emilyd61_uspInsertCustWapperfromWorkingData
@Run INT
AS
DECLARE @NUM INT = (SELECT COUNT(*) FROM [WorkingCustomerData])
DECLARE @ID INT
DECLARE @CID INT
DECLARE @FName varchar(50)
DECLARE @LName varchar(50)
DECLARE @PNum varchar(50)
DECLARE @EMAIL varchar(100)
DECLARE @D_OB date
DECLARE @AddID INT
DECLARE @ST varchar(50)
DECLARE @ZipC int

WHILE @Run > 0
BEGIN
SET @ID = (SELECT MIN(CustomerID) FROM [WorkingCustomerData])
SET @FName = (SELECT [CustomerFname] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @LName = (SELECT [CustomerLname] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @PNum = (SELECT [PhoneNum] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @EMAIL = (SELECT [Email] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @D_OB = (SELECT [DateOfBirth] FROM [WorkingCustomerData] WHERE CustomerID = @ID)
SET @AddID = (SELECT AddressID FROM tblAddress WHERE AddressID = @AddID)

EXEC emilyd61_uspGetAddressID
@Street = @ST,
@Zipcode = @ZipC,
@Address_ID = @AddID

BEGIN TRAN G1
INSERT INTO tblCustomer (FirstName, LastName, PhoneNumber, Email, DOB, AddressID)
VALUES (@FName, @LName, @PNum, @EMAIL, @D_OB, @AddID)
SET @CID = (SELECT SCOPE_IDENTITY())

IF @@ERROR <> 0
ROLLBACK TRAN G1
ELSE
COMMIT TRAN G1

SET @Run = @Run -1
END



/*2) Check constraint*/
-- Emily Ding
/* No under 18 years old seller*/
ALTER FUNCTION fn_No18Seller()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (SELECT *
			FROM tblOffering O JOIN tblCustomer C ON O.SellerID = C.CustomerID
							JOIN tblProduct P ON O.ProductID = P.ProductID
			WHERE C.DOB < (SELECT GetDate() - (365.25 * 18)))
SET @Ret = 1
RETURN @Ret
END
GO

ALTER TABLE tblOffering
ADD CONSTRAINT CK_No18Seller
CHECK (dbo.fn_No18Seller() = 0)

/*All the total price in each order should at least $10.00 (min pay is 10.00)*/
CREATE FUNCTION fn_minOrderPay10()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (SELECT *
			FROM tblOrder ORD JOIN tblLineItem L ON ORD.OrderID = L.OrderID
			JOIN tblOffering O ON L.OfferingID = O.OfferingID
			GROUP BY ORD.OrderID
			HAVING SUM(O.Price) < 10)
SET @Ret = 1
RETURN @Ret
END
GO

ALTER TABLE tblOrder
ADD CONSTRAINT CK_minPayLessThan10
CHECK (dbo.fn_minOrderPay10() = 0)


/*3) Computed column*/
-- Emily Ding
/*Customer age*/
CREATE FUNCTION fn_customerAge(@CustID INT)
RETURNS INT
AS
BEGIN
	DECLARE @Ret INT
	SET @Ret = (SELECT DATEDIFF(YEAR, DOB, GETDATE()) AS Age
				FROM tblCustomer C)
RETURN @Ret
END
-- Alter table
ALTER TABLE tblCustomer
ADD CustAge AS (dbo.fn_customerAge(CustomerID))

/*Sell Tax rate: Seattle, it's 10.1% */
CREATE FUNCTION fn_SalesTax(@OffID INT)
RETURNS INT
AS
BEGIN
	DECLARE @Ret INT
	SET @Ret = (SELECT Price * .101 AS TaxFee
				FROM tblOffering)
RETURN @Ret
END
-- Alter table
ALTER TABLE tblOffering
Add SellTaxFee AS (dbo.fn_SalesTax(OfferingID))


/*4) View*/
-- Emily Ding
/*How many customers who age over 50 years old buy 'Gears' products over 100 dollars in 1 order
as well as buy all the products over 1000 dollors including the 'Seed'*/

CREATE VIEW TotalCustomerNumOver50
AS
SELECT COUNT(C.CustomerID) AS TotalCustNum
FROM tblCustomer C
	JOIN tblOrder ORD ON C.CustomerID = ORD.CustomerID
	JOIN tblLineItem L ON L.OrderID = ORD.OrderID
	JOIN tblOffering O ON L.OfferingID = O.OfferingID
	JOIN tblProduct P ON O.ProductID = P.ProductID
	JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
WHERE C.DOB > (SELECT GetDate() - (365.25 * 50)) AND
	PT.ProductTypeName = 'Seed' AND
	C.CustomerID IN	(SELECT C.CustomerID
					FROM  tblCustomer C
					JOIN tblOrder ORD ON C.CustomerID = ORD.CustomerID
					JOIN tblLineItem L ON L.OrderID = ORD.OrderID
					JOIN tblOffering O ON L.OfferingID = O.OfferingID
					JOIN tblProduct P ON O.ProductID = P.ProductID
					JOIN tblProductType PT ON P.ProductTypeID = PT.ProductTypeID
					WHERE PT.ProductTypeName = 'Gears'
					GROUP BY C.CustomerID
					HAVING SUM(O.Price) > 100 AND COUNT(ORD.OrderID) = 1)
GROUP BY C.CustomerID
HAVING SUM(O.Price) > 1000

/*How many '5 stars' reviewed by 'Loyal' customers
who also are sellers that sold 10000 dollars*/
CREATE VIEW TotalCustSellerNum5star
AS
SELECT COUNT(C.CustomerID) AS TotalCustSellerNum
FROM tblCustomer C JOIN tblCustomerCustomerType CCT
	ON C.CustomerID = CCT.CustomerID
	JOIN tblCustomerType CT ON CCT.CustTypeID = CT.CustTypeID
	JOIN tblReview R ON C.CustomerID = R.CustomerID
	JOIN tblRating RA ON R.RatingID = RA.RatingID
WHERE RA.RatingName = '5 stars' AND CT.CustTypeName = 'Loyal' AND
	C.CustomerID = R.SellerID AND 
	R.SellerID IN (SELECT C.CustomerID
					FROM  tblCustomer C
					JOIN tblOrder ORD ON C.CustomerID = ORD.CustomerID
					JOIN tblLineItem L ON L.OrderID = ORD.OrderID
					JOIN tblOffering O ON L.OfferingID = O.OfferingID
					GROUP BY C.CustomerID
					HAVING SUM(O.Price) > 10000)
GROUP BY C.CustomerID


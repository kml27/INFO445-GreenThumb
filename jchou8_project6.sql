/* Stored procedures */


/* Business rules */
/* Customers cannot review themselves */
CREATE FUNCTION fn_NoSelfReview()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (
	SELECT ReviewID
	FROM tblReview
	WHERE CustomerID = SellerID
)
	SET @Ret = 1
RETURN @Ret
END

GO

ALTER TABLE tblReview
ADD CONSTRAINT CK_NoSelfReview
CHECK (dbo.fn_NoSelfReview() = 0)

GO

/* Only customers with type 'seller' can have offerings */
CREATE FUNCTION fn_OnlySellersOffer()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT = 0
IF EXISTS (
	SELECT O.OfferingID
	FROM tblOffering O
	JOIN tblCustomer C ON C.CustomerID = O.SellerID
	WHERE NOT C.CustomerID IN (
		SELECT C.CustomerID
		FROM tblCustomer C
		JOIN tblCustomerCustomerType CCT ON CCT.CustomerID = C.CustomerID
		JOIN tblCustomerType CT ON CT.CustTypeID = CCT.CustTypeID
		WHERE CT.CustTypeName = 'Seller'
	)
)
	SET @Ret = 1
RETURN @Ret
END

GO

ALTER TABLE tblOffering
ADD CONSTRAINT CK_OnlySellersOffer
CHECK (dbo.fn_OnlySellersOffer() = 0)

GO

/* Computed columns */
/* Line item subtotal */
CREATE FUNCTION fn_LineItemSubtotal(@LineItemID INT)
RETURNS Money
AS
BEGIN
DECLARE @Ret Money
SET @Ret = (SELECT O.Price * LI.Qty
FROM tblLineItem LI
JOIN tblOffering O ON LI.OfferingID = O.OfferingID
WHERE LI.LineItemID = @LineItemID
)
RETURN @Ret
END

GO

ALTER TABLE tblLineItem
ADD Subtotal AS (dbo.fn_LineItemSubtotal(LineItemID))

GO

/* Order total */
CREATE FUNCTION fn_OrderTotal(@OrderID INT)
RETURNS INT
AS
BEGIN
DECLARE @Ret INT
SET @Ret = (SELECT SUM(LI.Subtotal)
FROM tblOrder O
JOIN tblLineItem LI ON LI.OrderID = O.OrderID
WHERE O.OrderID = @OrderID
)
RETURN @Ret
END

GO

ALTER TABLE tblOrder
ADD Total AS (dbo.fn_OrderTotal(OrderID))

GO

/* Views */


USE GREEN_THUMB
GO

/* View structure of our offering table */
SELECT * FROM tblOffering O

/* Simple query - Who in Washington is currently selling broccoli? */
SELECT * FROM tblOffering O
JOIN tblAddress A ON A.AddressID = O.AddressID
JOIN tblProduct P ON P.ProductID = O.ProductID
WHERE A.State = 'Washington, WA'
AND P.ProductName = 'Broccoli'

/* Look for a product */
SELECT * FROM tblPRODUCT
WHERE ProductName LIKE '%Turnip%'

/* Add an offering */
DECLARE @Today DATE = (SELECT GETDATE())
EXEC jchou8_uspInsertOffering
@SellFname = 'Ora',
@SellLname = 'Balboa',
@SellDOB = '1932-01-29',
@ProdName = 'Turnip',
@AddSt = '27714 NW Evans Heights Lane',
@AddCity = 'Seattle',
@AddState = 'Washington, WA',
@AddZip = '98107',
@Price = '1.12',
@Name = 'selling turnips wow',
@Desc = 'these good turnips yes',
@Start = @Today

/* Check out our new offering */
SELECT TOP 10 *
FROM tblOffering
ORDER BY StartDate DESC

-- add 100 Details
SELECT COUNT(*) FROM tblDetail
EXEC josiahc_uspSyntheticDetail
@numberOfTimes = 100
GO
SELECT COUNT(*) FROM tblDetail

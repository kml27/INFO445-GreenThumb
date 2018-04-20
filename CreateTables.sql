CREATE DATABASE GREEN_THUMB
USE GREEN_THUMB

CREATE TABLE tblAddress(
AddressID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
StreetAddress varchar(50) NOT NULL,
City varchar(50) NOT NULL,
[State] varchar(50) NOT NULL,
Zip INT NOT NULL,
);

CREATE TABLE tblRating(
RatingID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
RatingName varchar(10) NOT NULL,
RatingDesc varchar(50) ,
);


CREATE TABLE tblReview(
ReviewID INT PRIMARY KEY IDENTITY(1, 1) NOT NULL,
CustomerID INT FOREIGN KEY REFERENCES tblCustomer(CustomerID) NOT NULL,
SellerID INT FOREIGN KEY REFERENCES tblCustomer(CustomerID) NOT NULL,
RatingID INT FOREIGN KEY REFERENCES tblRating(RatingID) NOT NULL,
ReviewTitle varchar(50) NOT NULL,
ReviewText varchar(1000) NOT NULL,
);

CREATE TABLE tblCustomer (
CustomerID INT IDENTITY(1,1) PRIMARY KEY not null,
FirstName varchar(100) not null,
LastName varchar(100) not null,
[PhoneNumber] varchar (20) not null,
Email varchar(100) not null,
DOB DATE not null,
AddressID INT FOREIGN KEY REFERENCES tblAddress (AddressID) not null
)

CREATE TABLE tblCustomerCustomerType (
CustCustTypeID INT IDENTITY(1,1) PRIMARY KEY not null,
CustomerID INT FOREIGN KEY REFERENCES tblCustomer (CustomerID) not null,
CustTypeID INT FOREIGN KEY REFERENCES tblCustomerType (CustTypeID) not null,
StartDate DATE,
EndDate DATE
)

CREATE TABLE tblCustomerType (
CustTypeID INT IDENTITY(1,1) PRIMARY KEY not null,
CustTypeName varchar(100) not null,
CustTypeDesc varchar(100)
)

CREATE TABLE tblProductType (
ProductTypeID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
ProductTypeName varchar(50) NOT NULL,
ProductTypeDesc varchar(500) NULL
)

CREATE TABLE tblProduct (
ProductID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
ProductTypeID INT FOREIGN KEY REFERENCES tblProductType(ProductTypeID) NOT NULL,
ProductName varchar(100) NOT NULL,
ProductDesc varchar(500) NULL
)

CREATE TABLE tblUnit
(UnitID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
UnitName VARCHAR(50) NOT NULL,
UnitAbbr VARCHAR(10) NOT NULL,
UnitDesc VARCHAR(500) NULL)

CREATE TABLE tblOffering
(OfferingID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
SellerID INT FOREIGN KEY REFERENCES tblCustomer(CustomerID) NOT NULL,
ProductID INT FOREIGN KEY REFERENCES tblProduct(ProductID) NOT NULL,
AddressID INT FOREIGN KEY REFERENCES tblAddress(AddressID) NOT NULL,	
Price MONEY NOT NULL,
OfferingName VARCHAR(50) NOT NULL,
OfferingDesc VARCHAR(2500) NULL,
StartDate DATE NOT NULL,
EndDate DATE NULL,
UnitID INT FOREIGN KEY REFERENCES tblUnit(UnitID) NOT NULL)

CREATE TABLE tblDetailType(
DetailTypeID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
DetailTypeName varchar(50) NOT NULL,
DetailTypeDesc varchar(500) NULL
)

CREATE TABLE tblDetail(
DetailID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
OfferingID INT FOREIGN KEY REFERENCES tblOffering(OfferingID) NOT NULL,
DetailTypeID INT FOREIGN KEY REFERENCES tblDetailType(DetailTypeID) NOT NULL,
UnitID INT FOREIGN KEY REFERENCES tblUnit(UnitID) NOT NULL,
DetailDesc varchar(500) NOT NULL
)

CREATE TABLE tblOrder
(OrderID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
CustomerID INT FOREIGN KEY REFERENCES tblCustomer(CustomerID) NOT NULL,
OrderDateTime DATETIME NOT NULL)

CREATE TABLE tblLineItem
(LineItemID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
OrderID INT FOREIGN KEY REFERENCES tblOrder(OrderID) NOT NULL,
OfferingID INT FOREIGN KEY REFERENCES tblOffering(OfferingID) NOT NULL,
Qty INT NOT NULL)


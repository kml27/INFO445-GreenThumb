CREATE TABLE tblAddress(
	AddressID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
	StreetAddress varchar(50) NOT NULL,
	City varchar(50) NOT NULL,
	[State] char(2) NOT NULL,
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
	SellerID INT FOREIGN KEY REFERENCES tblCustomer(CUstomerID) NOT NULL,
	RatingID INT FOREIGN KEY REFERENCES tblRating(RatingID) NOT NULL,
	ReviewTitle varchar(50) NOT NULL,
	ReviewText varchar(1000) NOT NULL,
);

CREATE TABLE tblProductType (
	ProductTypeID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
	ProductTypeName varchar(50) NOT NULL,
	ProductTypeDesc varchar(500) NULL
)

CREATE TABLE tblProduct(
	ProductID INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
	ProductTypeID INT FOREIGN KEY REFERENCES tblProductType(ProductTypeID) NOT NULL,
	ProductName varchar(100) NOT NULL,
	ProductDesc varchar(500) NULL
)

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
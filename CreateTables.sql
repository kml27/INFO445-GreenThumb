CREATE TABLE tblAddressID(
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
	CustromerID INT FOREIGN KEY REFERENCES tblCustomer(CustomerID) NOT NULL,
	SellerID INT FOREIGN KEY REFERENCES tblCustomer(CUstomerID) NOT NULL,
	RatingID INT FOREIGN KEY REFERENCES tblRating(RatingID) NOT NULL,
	ReviewTitle varchar(50) NOT NULL,
	ReviewText varchar(1000) NOT NULL,
);

CREATE TABLE tblCustomer (
	CustomerID INT IDENTITY(1,1) PRIMARY KEY not null,
	FirstName varchar(100) not null,
	LastName varchar(100) not null,
	PhoneNumber int not null,
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



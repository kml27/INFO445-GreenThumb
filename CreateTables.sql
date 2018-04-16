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





CREATE TABLE User (
	username varchar(50) PRIMARY KEY,
    firstName varchar(20),
    lastName varchar(20),
    address varchar(50),
    password varchar(50) NOT NULL,
    phoneNumber integer
);

CREATE TABLE Driver (
	username varchar(50) PRIMARY KEY REFERENCES User (username),
	d_rating integer,
	license_no integer
);

CREATE TABLE Passenger (
	username varchar(50) PRIMARY KEY REFERENCES User (username),
	p_rating integer
);

CREATE TABLE Model (
	name varchar(20) PRIMARY KEY,
    size integer
);

CREATE TABLE Car (
	plate number varchar(20) PRIMARY KEY,
    colours  varchar(20)
);

CREATE TABLE Promo (
	promoCode varchar(20) PRIMARY KEY,
	quotaLeft integer,
	maxDiscount integer,
	minPrice integer,
	discount integer	
);

CREATE TABLE Ride (
	rideID varchar(20) PRIMARY KEY,
    p_comment varchar(50),
    p_rating integer,
    d_comment varchar(50),
    d_rating integer	
);

CREATE TABLE Advertisement (
	timePosted integer PRIMARY KEY,
    numPassengers integer,
    departureTime integer,
    price integer,
    to varchar(50),
    from varchar(50)
);


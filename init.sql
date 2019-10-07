CREATE TABLE User (
	username varchar(50) PRIMARY KEY,
    firstName varchar(20) NOT NULL,
    lastName varchar(20) NOT NULL,
    address varchar(50) NOT NULL,
    password varchar(50) NOT NULL,
    phoneNumber integer NOT NULL
);

CREATE TABLE Driver (
	username varchar(50) PRIMARY KEY REFERENCES User (username),
	d_rating integer,
	license_no integer NOT NULL
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
	plateNumber varchar(20) PRIMARY KEY,
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
    numPassengers integer NOT NULL,
    departureTime integer NOT NULL,
    price integer NOT NULL,
    to varchar(50) NOT NULL,
    from varchar(50) NOT NULL
);




/****************************************************************
DATA INSERTION
****************************************************************/
insert into User values ('user1', 'Cart', 'Klemensiewicz', '88 Hudson Crossing', 'password', 2863945039);
insert into User values ('user2', 'Kit', 'Thurlow', '56695 Cambridge Hill', 'password', 8215865769);
insert into User values ('user3', 'Brynna', 'Fetter', '6683 Sundown Park', 'password', 7734451473);
insert into User values ('user4', 'Silvester', 'Churly', '82 Bellgrove Pass', 'password', 1365739490);
insert into User values ('user5', 'Hugo', 'Shoesmith', '7 Sunfield Lane', 'password', 3436796564);
insert into User values ('user6', 'Theodor', 'MacCostigan', '6 Chive Crossing', 'password', 2055996866);
insert into User values ('user7', 'Heriberto', 'Antusch', '981 Briar Crest Way', 'password', 3029039526);
insert into User values ('user8', 'Georgia', 'Morgue', '6972 Carberry Point', 'password', 5377426205);
insert into User values ('user9', 'Marius', 'Reavell', '8544 Eggendart Lane', 'password', 9725999259);
insert into User values ('user10', 'Pennie', 'Nelle', '2 Ridgeview Drive', 'password', 2645471052);
insert into User values ('user11', 'Derick', 'Kennaway', '76300 Kim Junction', 'password', 5185617186);
insert into User values ('user12', 'Othelia', 'Divine', '66 Esch Parkway', 'password', 9182609085);
insert into User values ('user13', 'Concordia', 'Kobierra', '42 Esker Way', 'password', 5544703777);
insert into User values ('user14', 'Sonnie', 'Llop', '4336 2nd Terrace', 'password', 3995005082);
insert into User values ('user15', 'Estella', 'McCroary', '16 Holmberg Drive', 'password', 4832356120);
insert into User values ('user16', 'Joanie', 'Wanley', '17902 Summit Point', 'password', 7106811550);
insert into User values ('user17', 'Hillary', 'Izon', '50 Fuller Road', 'password', 5355440695);
insert into User values ('user18', 'Hew', 'Leakner', '93231 Starling Junction', 'password', 4794001078);
insert into User values ('user19', 'Mallissa', 'Mahmood', '90 Loftsgordon Road', 'password', 9435003533);
insert into User values ('user20', 'Jocelyn', 'Seabrook', '68 Mifflin Junction', 'password', 6749453810);

INSERT INTO Driver VALUES ('user4', )

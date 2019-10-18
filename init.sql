/*****************
For our own debuggging only
******************/
DROP TABLE IF EXISTS App_User CASCADE;
DROP TABLE IF EXISTS Driver CASCADE;
DROP TABLE IF EXISTS Passenger CASCADE;
DROP TABLE IF EXISTS Model CASCADE;
DROP TABLE IF EXISTS Car CASCADE;
DROP TABLE IF EXISTS Promo CASCADE;
DROP TABLE IF EXISTS Scheduled_Ride CASCADE;
DROP TABLE IF EXISTS Place CASCADE;
DROP TABLE IF EXISTS Advertisement CASCADE;
DROP TABLE IF EXISTS Creates CASCADE;
DROP TABLE IF EXISTS Bids CASCADE;
DROP TABLE IF EXISTS Review CASCADE;
DROP TABLE IF EXISTS Redeems CASCADE;
DROP TABLE IF EXISTS Owns CASCADE;
DROP TABLE IF EXISTS Belongs CASCADE;


/********
ENTITY TABLES
***********/
BEGIN TRANSACTION;

CREATE TABLE App_User (
    username     varchar(50) PRIMARY KEY,
    first_name   varchar(20) NOT NULL,
    last_name    varchar(20) NOT NULL,
    password     varchar(50) NOT NULL,
    phone_number varchar(20) NOT NULL
);

CREATE TABLE Driver (
    username     varchar(50) PRIMARY KEY REFERENCES App_User ON DELETE CASCADE,
    d_rating     INTEGER
);

CREATE TABLE Passenger (
    username varchar(50) PRIMARY KEY REFERENCES App_User ON DELETE CASCADE,
    p_rating INTEGER
);

CREATE TABLE Model (
    brand   TEXT,
    name    TEXT,
    size    INTEGER NOT NULL,
    PRIMARY KEY (brand, name)
);

CREATE TABLE Car (
    plate_number varchar(20) PRIMARY KEY,
    colours      varchar(20) NOT NULL
);

CREATE TABLE Promo (
    promo_code   varchar(20) PRIMARY KEY,
    quota_left   INTEGER NOT NULL,
    max_discount INTEGER,
    min_price    INTEGER,
    discount     INTEGER NOT NULL
);

CREATE TABLE Place (
    name varchar(50) PRIMARY KEY
);

CREATE TABLE Advertisement (
    time_posted       TIMESTAMP   DEFAULT date_trunc('second', current_timestamp),
    driver_ID         varchar(50) REFERENCES Driver ON DELETE CASCADE,
    num_passengers    INTEGER     NOT NULL,
    departure_time    TIMESTAMP   NOT NULL,
    price             INTEGER     NOT NULL,
    to_place          varchar(50) NOT NULL REFERENCES Place,
    from_place        varchar(50) NOT NULL REFERENCES Place,

    PRIMARY KEY (time_posted, driver_ID)
);


/****************************************************************
RELATIONSHIPS
****************************************************************/

CREATE TABLE Bids (
    passenger_ID     varchar(50) REFERENCES Passenger ON DELETE CASCADE,
    driver_ID        varchar(50) REFERENCES Driver    ON DELETE CASCADE,
    time_posted      TIMESTAMP,
    price            NUMERIC,
    status           varchar(20),
    no_passengers    INTEGER,
    PRIMARY KEY (passenger_ID, time_posted, driver_ID),
    CHECK       (passenger_ID <> driver_ID),
    CHECK       (status = 'ongoing' OR status = 'successful' OR status = 'failed')
);

CREATE TABLE Scheduled_Ride (
    ride_ID        SERIAL      PRIMARY KEY,
    passenger_ID   varchar(50) NOT NULL,
    driver_ID      varchar(50) NOT NULL,
    time_posted    TIMESTAMP   NOT NULL,
    status         varchar(20) DEFAULT 'pending',
    FOREIGN KEY (passenger_ID, time_posted, driver_ID) REFERENCES Bids,

    CHECK (status = 'pending' OR status = 'ongoing' OR status = 'completed')
);

CREATE TABLE Review (
    rideID      INTEGER PRIMARY KEY REFERENCES Scheduled_Ride ON DELETE CASCADE,
    p_comment   varchar(50),
    p_rating    INTEGER,
    d_comment   varchar(50),
    d_rating    INTEGER
);

CREATE TABLE Redeems (
    ride_ID       INTEGER     PRIMARY KEY  REFERENCES Scheduled_Ride,
    promo_code    varchar(20) NOT NULL     REFERENCES Promo,
    username      varchar(50) NOT NULL     REFERENCES Passenger
);

CREATE TABLE Owns (
    driver_ID    varchar(50) REFERENCES Driver,
    plate_number varchar(20) REFERENCES Car,
    PRIMARY KEY (driver_ID, plate_number)
);

CREATE TABLE Belongs (
    plate_number varchar(20) REFERENCES Car,
    brand       TEXT        NOT NULL,
    name        TEXT        NOT NULL,
    PRIMARY KEY (plate_number),
    FOREIGN KEY (brand, name) REFERENCES Model
);

COMMIT;

/****************************************************************
DATA INSERTION
****************************************************************/
insert into App_User values ('user1', 'Cart', 'Klemensiewicz', 'password', 2863945039);
insert into App_User values ('user2', 'Kit', 'Thurlow', 'password', 8215865769);
insert into App_User values ('user3', 'Brynna', 'Fetter', 'password', 7734451473);
insert into App_User values ('user4', 'Silvester', 'Churly', 'password', 1365739490);
insert into App_User values ('user5', 'Hugo', 'Shoesmith', 'password', 3436796564);
insert into App_User values ('user6', 'Theodor', 'MacCostigan', 'password', 2055996866);
insert into App_User values ('user7', 'Heriberto', 'Antusch', 'password', 3029039526);
insert into App_User values ('user8', 'Georgia', 'Morgue', 'password', 5377426205);
insert into App_User values ('user9', 'Marius', 'Reavell', 'password', 9725999259);
insert into App_User values ('user10', 'Pennie', 'Nelle', 'password', 2645471052);
insert into App_User values ('user11', 'Derick', 'Kennaway', 'password', 5185617186);
insert into App_User values ('user12', 'Othelia', 'Divine', 'password', 9182609085);
insert into App_User values ('user13', 'Concordia', 'Kobierra', 'password', 5544703777);
insert into App_User values ('user14', 'Sonnie', 'Llop', 'password', 3995005082);
insert into App_User values ('user15', 'Estella', 'McCroary', 'password', 4832356120);
insert into App_User values ('user16', 'Joanie', 'Wanley', 'password', 7106811550);
insert into App_User values ('user17', 'Hillary', 'Izon', 'password', 5355440695);
insert into App_User values ('user18', 'Hew', 'Leakner', 'password', 4794001078);
insert into App_User values ('user19', 'Mallissa', 'Mahmood', 'password', 9435003533);
insert into App_User values ('user20', 'Jocelyn', 'Seabrook', 'password', 6749453810);

insert into Passenger values ('user1');
insert into Passenger values ('user2');
insert into Passenger values ('user3');
insert into Passenger values ('user4');
insert into Passenger values ('user5');
insert into Passenger values ('user6');
insert into Passenger values ('user7');
insert into Passenger values ('user8');
insert into Passenger values ('user9');
insert into Passenger values ('user10');
insert into Passenger values ('user11');
insert into Passenger values ('user12');
insert into Passenger values ('user13');
insert into Passenger values ('user14');
insert into Passenger values ('user15');
insert into Passenger values ('user16');
insert into Passenger values ('user17');
insert into Passenger values ('user18');
insert into Passenger values ('user19');
insert into Passenger values ('user20');

-- Driver: username, d_rating(NULL)
INSERT INTO Driver VALUES ('user1', NULL);
INSERT INTO Driver VALUES ('user2', NULL);
INSERT INTO Driver VALUES ('user3', NULL);

-- Model: brand, name, size
INSERT INTO Model VALUES ('Toyota', 'Mirai', 5);
INSERT INTO Model VALUES ('Toyota', 'Prius', 5);
INSERT INTO Model VALUES ('Toyota', 'Camry', 5);
INSERT INTO Model VALUES ('Honda', 'Civic', 5);
INSERT INTO Model VALUES ('Honda', 'CRV', 7);
INSERT INTO Model VALUES ('Lexus', 'X1', 5);

-- Car: plateNumber, colors
INSERT INTO Car VALUES ('SFV7687J', 'White');
INSERT INTO Car VALUES ('S1', 'White');
INSERT INTO Car VALUES ('EU9288C', 'Gray');

-- Promo: promoCode, quotaLeft, maxDiscount, minPrice, disc
INSERT INTO Promo VALUES ('a1a', 10, 20, 10, 20);
INSERT INTO Promo VALUES ('a1b', 1, 10, 0, 20);

-- Place: name (of place)
INSERT INTO Place VALUES ('Jurong East');
INSERT INTO Place VALUES ('Bukit Batok');
INSERT INTO Place VALUES ('Bukit Gombak');
INSERT INTO Place VALUES ('Choa Chu Kang');
INSERT INTO Place VALUES ('Yew Tee');
INSERT INTO Place VALUES ('Kranji');
INSERT INTO Place VALUES ('Marsiling');
INSERT INTO Place VALUES ('Woodlands');
INSERT INTO Place VALUES ('Admiralty');
INSERT INTO Place VALUES ('Sembawang');
INSERT INTO Place VALUES ('Canberra');
INSERT INTO Place VALUES ('Yishun');
INSERT INTO Place VALUES ('Khatib');
INSERT INTO Place VALUES ('Yio Chu Kang');
INSERT INTO Place VALUES ('Ang Mo Kio');
INSERT INTO Place VALUES ('Bishan');
INSERT INTO Place VALUES ('Braddell');
INSERT INTO Place VALUES ('Toa Payoh');
INSERT INTO Place VALUES ('Novena');
INSERT INTO Place VALUES ('Newton');
INSERT INTO Place VALUES ('Orchard');
INSERT INTO Place VALUES ('Somerset');
INSERT INTO Place VALUES ('Dhoby Ghaut');
INSERT INTO Place VALUES ('City Hall');
INSERT INTO Place VALUES ('Raffles Place');
INSERT INTO Place VALUES ('Marina Bay');
INSERT INTO Place VALUES ('Marina South Pier');
INSERT INTO Place VALUES ('Pasir Ris');
INSERT INTO Place VALUES ('Tampines');
INSERT INTO Place VALUES ('Simei');
INSERT INTO Place VALUES ('Tanah Merah');
INSERT INTO Place VALUES ('Bedok');
INSERT INTO Place VALUES ('Kembangan');
INSERT INTO Place VALUES ('Eunos');
INSERT INTO Place VALUES ('Paya Lebar');
INSERT INTO Place VALUES ('Ajunied');
INSERT INTO Place VALUES ('Kallang');
INSERT INTO Place VALUES ('Lavender');
INSERT INTO Place VALUES ('Bugis');
INSERT INTO Place VALUES ('Tanjong Pagar');
INSERT INTO Place VALUES ('Outram Park');
INSERT INTO Place VALUES ('Tiong Bahru');
INSERT INTO Place VALUES ('Redhill');
INSERT INTO Place VALUES ('Queenstown');
INSERT INTO Place VALUES ('Commonwealth');
INSERT INTO Place VALUES ('Buona Vista');
INSERT INTO Place VALUES ('Dover');
INSERT INTO Place VALUES ('Clementi');
INSERT INTO Place VALUES ('Chinese Garden');
INSERT INTO Place VALUES ('Lakeside');
INSERT INTO Place VALUES ('Boon Lay');
INSERT INTO Place VALUES ('Pioneer');
INSERT INTO Place VALUES ('Joo Koon');
INSERT INTO Place VALUES ('Gul Circle');
INSERT INTO Place VALUES ('Tuas Crescent');
INSERT INTO Place VALUES ('Tuas West Road');
INSERT INTO Place VALUES ('Tuas Link');
INSERT INTO Place VALUES ('Expo');
INSERT INTO Place VALUES ('Changi Airport');
INSERT INTO Place VALUES ('Harborfront');
INSERT INTO Place VALUES ('Chinatown');
INSERT INTO Place VALUES ('Clarke Quay');
INSERT INTO Place VALUES ('Little India');
INSERT INTO Place VALUES ('Farrer Park');
INSERT INTO Place VALUES ('Boon Keng');
INSERT INTO Place VALUES ('Potong Pasir');
INSERT INTO Place VALUES ('Woodleigh');
INSERT INTO Place VALUES ('Serangoon');
INSERT INTO Place VALUES ('Kovan');
INSERT INTO Place VALUES ('Hougang');
INSERT INTO Place VALUES ('Buangkok');
INSERT INTO Place VALUES ('Sengkang');
INSERT INTO Place VALUES ('Punggol');
INSERT INTO Place VALUES ('Bras Basah');
INSERT INTO Place VALUES ('Esplanade');
INSERT INTO Place VALUES ('Promenade');
INSERT INTO Place VALUES ('Nicol Highway');
INSERT INTO Place VALUES ('Stadium');
INSERT INTO Place VALUES ('Mountbatten');
INSERT INTO Place VALUES ('Dakota');
INSERT INTO Place VALUES ('Mac Pherson');
INSERT INTO Place VALUES ('Tai Seng');
INSERT INTO Place VALUES ('Bartley');
INSERT INTO Place VALUES ('Lorong Chuan');
INSERT INTO Place VALUES ('Marymount');
INSERT INTO Place VALUES ('Caldecoot');
INSERT INTO Place VALUES ('Botanic Gardens');
INSERT INTO Place VALUES ('Farrer Road');
INSERT INTO Place VALUES ('Holland Village');
INSERT INTO Place VALUES ('One North');
INSERT INTO Place VALUES ('Kent Ridge');
INSERT INTO Place VALUES ('Haw Par Villa');
INSERT INTO Place VALUES ('Pasir Panjang');
INSERT INTO Place VALUES ('Labrador Park');
INSERT INTO Place VALUES ('Telok Blangah');
INSERT INTO Place VALUES ('Bayfront');
INSERT INTO Place VALUES ('Marina Bay');
INSERT INTO Place VALUES ('Bukit Panjang');
INSERT INTO Place VALUES ('Cashew');
INSERT INTO Place VALUES ('Hillview');
INSERT INTO Place VALUES ('Beauty World');
INSERT INTO Place VALUES ('King Albert Park');
INSERT INTO Place VALUES ('Sixth Avenue');
INSERT INTO Place VALUES ('Tan Kah Kee');
INSERT INTO Place VALUES ('Stevens');
INSERT INTO Place VALUES ('Rochor');
INSERT INTO Place VALUES ('Downtown');
INSERT INTO Place VALUES ('Telok Ayer');
INSERT INTO Place VALUES ('Fort Canning');
INSERT INTO Place VALUES ('Bencoolen');
INSERT INTO Place VALUES ('Jalan Besar');
INSERT INTO Place VALUES ('Bendemeer');
INSERT INTO Place VALUES ('Geylang Bahru');
INSERT INTO Place VALUES ('Mattar');
INSERT INTO Place VALUES ('Ubi');
INSERT INTO Place VALUES ('Kaki Bukit');
INSERT INTO Place VALUES ('Bedok North');
INSERT INTO Place VALUES ('Bedok Reservoir');
INSERT INTO Place VALUES ('Tampines West');
INSERT INTO Place VALUES ('Tampines East');
INSERT INTO Place VALUES ('Upper Changi');

-- Advertisement: timePosted(DEFAULT), driverID, numPass, departTime, price, to, from
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user1', 2, TIMESTAMP '2019-12-12 12:34', 20, 'Joo Koon', 'Bendemeer');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user2', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Changi Airport', 'Paya Lebar');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user3', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Joo Koon', 'Pasir Ris');

-- Bids: passId, driverID, timePosted, price, status, numPass
INSERT INTO Bids VALUES ('user11', 'user3', TIMESTAMP '2018-12-10 12:30', 10, 'ongoing', 2);
INSERT INTO Bids VALUES ('user12', 'user3', TIMESTAMP '2018-12-10 12:30', 20, 'ongoing', 2);
INSERT INTO Bids VALUES ('user13', 'user3', TIMESTAMP '2018-12-10 12:30', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user11', 'user2', TIMESTAMP '2018-12-10 12:30', 10, 'ongoing', 2);
INSERT INTO Bids VALUES ('user14', 'user2', TIMESTAMP '2018-12-10 12:30', 20, 'ongoing', 2);
INSERT INTO Bids VALUES ('user15', 'user2', TIMESTAMP '2018-12-10 12:30', 30, 'ongoing', 2);

-- Ride: rideID(NULL), passID, driverID, timePosted, status
INSERT INTO Scheduled_Ride VALUES(DEFAULT, 'user11', 'user3', TIMESTAMP '2019-12-12 12:30', DEFAULT);
INSERT INTO Scheduled_Ride VALUES(DEFAULT, 'user14', 'user2', TIMESTAMP '2019-12-12 12:30', 'ongoing');

-- Owns: driverID, plateNum
INSERT INTO Owns VALUES ('user1', 'SFV7687J');
INSERT INTO Owns VALUES ('user2', 'S1');
INSERT INTO Owns VALUES ('user3', 'EU9288C');

-- Belongs: plateNum, name, brand
INSERT INTO Belongs VALUES ('SFV7687J', 'Toyota', 'Mirai');
INSERT INTO Belongs VALUES ('S1', 'Toyota', 'Mirai');
INSERT INTO Belongs VALUES ('EU9288C', 'Honda', 'CRV');

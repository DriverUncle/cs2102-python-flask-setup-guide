/*****************
For our own debuggging only
******************/
DROP TABLE IF EXISTS App_User CASCADE;
DROP TABLE IF EXISTS Driver CASCADE;
DROP TABLE IF EXISTS Passenger CASCADE;
DROP TABLE IF EXISTS Car CASCADE;
DROP TABLE IF EXISTS Promo CASCADE;
DROP TABLE IF EXISTS Ride CASCADE;
DROP TABLE IF EXISTS Place CASCADE;
DROP TABLE IF EXISTS Advertisement CASCADE;
DROP TABLE IF EXISTS Bids CASCADE;
DROP TABLE IF EXISTS Redeems CASCADE;
DROP TABLE IF EXISTS Owns CASCADE;


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
    d_rating     NUMERIC
);

CREATE TABLE Passenger (
    username varchar(50) PRIMARY KEY REFERENCES App_User ON DELETE CASCADE,
    p_rating NUMERIC
);

CREATE TABLE Car (
    plate_number    varchar(20) PRIMARY KEY,
    colour          varchar(20) NOT NULL,
    brand           varchar(20) NOT NULL,
    no_passengers   INTEGER NOT NULL,
    CHECK(no_passengers >= 1)
);

CREATE TABLE Promo (
    promo_code  varchar(20) PRIMARY KEY,
    max_quota   INTEGER NOT NULL,
    min_price   INTEGER,
    discount    INTEGER NOT NULL
);

CREATE TABLE Place (
    name varchar(50) PRIMARY KEY
);

CREATE TABLE Advertisement (
    time_posted       TIMESTAMP   DEFAULT date_trunc('second', current_timestamp),
    driver_ID         varchar(50) REFERENCES Driver ON DELETE CASCADE,
    num_passengers    INTEGER     NOT NULL,
    departure_time    TIMESTAMP   NOT NULL,
    price             INTEGER     NOT NULL, -- minimum bidding price for the advertisement
    to_place          varchar(50) NOT NULL REFERENCES Place,
    from_place        varchar(50) NOT NULL REFERENCES Place,
    ad_status         varchar(20) NOT NULL,
    PRIMARY KEY (time_posted, driver_ID),
    CHECK       (num_passengers > 0),
    CHECK       (ad_status = 'Active' OR ad_status = 'Scheduled' OR ad_status = 'Deleted')
);


/****************************************************************
RELATIONSHIPS
****************************************************************/

CREATE TABLE Bids (
    passenger_ID     varchar(50) REFERENCES Passenger ON DELETE CASCADE,
    driver_ID        varchar(50) REFERENCES Driver    ON DELETE CASCADE,
    time_posted      TIMESTAMP	 DEFAULT date_trunc('second', current_timestamp),
    price            NUMERIC,
    status           varchar(20),
    no_passengers    INTEGER,
    PRIMARY KEY (passenger_ID, time_posted, driver_ID),
    CHECK       (passenger_ID <> driver_ID),
    CHECK       (status = 'ongoing' OR status = 'successful' OR status = 'failed'),
    CHECK       (price > 0)
);

CREATE TABLE Ride (
    ride_ID        SERIAL      PRIMARY KEY,
    passenger_ID   varchar(50) NOT NULL,
    driver_ID      varchar(50) NOT NULL,
    time_posted    TIMESTAMP   NOT NULL,
    status         varchar(20) DEFAULT 'pending',
    is_paid        BOOLEAN NOT NULL DEFAULT false,
    p_comment   varchar(50),
    p_rating    numeric,
    d_comment   varchar(50),
    d_rating    numeric,
    FOREIGN KEY (passenger_ID, time_posted, driver_ID) REFERENCES Bids,
    CHECK (status = 'pending' OR status = 'ongoing' OR status = 'completed')
);

CREATE TABLE Redeems (
    ride_ID       INTEGER     PRIMARY KEY  REFERENCES Ride,
    promo_code    varchar(20) NOT NULL     REFERENCES Promo,
    username      varchar(50) NOT NULL     REFERENCES Passenger
);

CREATE TABLE Owns (
    driver_ID    varchar(50) REFERENCES Driver,
    plate_number varchar(20) REFERENCES Car,
    PRIMARY KEY (driver_ID, plate_number)
);

/****************************************************************
FUNCTION and TRIGGER
****************************************************************/
CREATE OR REPLACE FUNCTION update_bid_failed()
RETURNS TRIGGER AS $$ BEGIN
RAISE NOTICE 'New bid price should be higher'; RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER bid_update_trig
BEFORE UPDATE ON bids FOR EACH ROW
WHEN (NEW.price < OLD.price)
EXECUTE PROCEDURE update_bid_failed();

CREATE OR REPLACE FUNCTION update_bid_status_to_fail()
RETURNS TRIGGER AS $$ BEGIN
    RAISE NOTICE 'Updating all non-winning bids for % % to failed', NEW.driver_ID, NEW.time_posted;
    UPDATE Bids AS b SET status = 'failed' 
    WHERE (b.time_posted, b.driver_ID) = (NEW.time_posted, NEW.driver_ID) AND b.status = 'ongoing';
    RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_ad_bid_on_successful_bid()
RETURNS TRIGGER AS $$ BEGIN
    RAISE NOTICE 'Updating advertisement for % % to Scheudled after a successful bid', NEW.driver_ID, NEW.time_posted;
    UPDATE Advertisement a SET ad_status = 'Scheduled'
        WHERE (a.time_posted, a.driver_ID) = (NEW.time_posted, NEW.driver_ID);
    RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER update_advertisement_on_successful_bid
AFTER UPDATE ON Bids FOR EACH ROW
WHEN (OLD.status = 'ongoing' AND NEW.status = 'successful')
EXECUTE PROCEDURE update_ad_bid_on_successful_bid();

CREATE TRIGGER update_ad_status
AFTER UPDATE ON Advertisement FOR EACH ROW
WHEN (NEW.ad_status = 'Deleted' OR NEW.ad_status = 'Scheduled')
EXECUTE PROCEDURE update_bid_status_to_fail();

CREATE OR REPLACE PROCEDURE
add_driver(name varchar(20)) AS
$tag$
BEGIN
IF NOT EXISTS(SELECT * FROM driver WHERE driver.username = name) THEN
    INSERT INTO driver(username, d_rating) VALUES (name, NULL);
END IF;
END
$tag$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE
add_owns(name varchar(20), number varchar(20)) AS
$tag$
BEGIN
IF NOT EXISTS(SELECT * FROM owns WHERE owns.driver_id = name AND owns.plate_number = number) THEN
    INSERT INTO owns(driver_id, plate_number) VALUES (name, number);
END IF;
END
$tag$
LANGUAGE plpgsql;


/*
TRIGGER AND FUNCTION FOR REVIEWS
 */

CREATE OR REPLACE FUNCTION
update_passenger_average_rating() RETURNS TRIGGER AS
$tag$
DECLARE average_rating numeric;
BEGIN
RAISE NOTICE 'Updating Average Passenger Rating';
SELECT ROUND(SUM(p_rating) / COUNT(*), 2) INTO average_rating FROM Ride WHERE passenger_id = OLD.passenger_id AND p_rating IS NOT NULL;
UPDATE Passenger SET p_rating = average_rating WHERE username = NEW.passenger_id;
RETURN NEW;
END;
$tag$
LANGUAGE plpgsql;

CREATE TRIGGER update_passenger_ride_rating
AFTER UPDATE ON ride FOR EACH ROW
WHEN ((OLD.p_rating <> NEW.p_rating OR OLD.p_rating IS NULL) AND NEW.p_rating IS NOT NULL)
EXECUTE PROCEDURE update_passenger_average_rating();

CREATE OR REPLACE FUNCTION
update_driver_average_ride_rating() RETURNS TRIGGER AS
$tag$
DECLARE average_rating numeric;
BEGIN
RAISE NOTICE 'Updating Average Driver Rating';
SELECT ROUND(SUM(d_rating) / COUNT(*), 2) INTO average_rating FROM Ride WHERE driver_id = OLD.driver_id AND d_rating IS NOT NULL;
UPDATE Driver SET d_rating = average_rating WHERE username = NEW.driver_id;
RETURN NEW;
END;
$tag$
LANGUAGE plpgsql;

CREATE TRIGGER update_driver_ride_rating
AFTER UPDATE ON ride FOR EACH ROW
EXECUTE PROCEDURE update_driver_average_ride_rating();

COMMIT; -- Commit once all table insertions and triggers are successful.

/*
TRIGGER AND FUNCTION FOR PREVENTING USERS THAT HAS NOT PAID FOR SUCCESSFUL RIDE, FROM INSERTING OR UPDATING OTHER TABLES EXCEPT PAYMENT TABLE
 */

/****************************************************************
DATA INSERTION
****************************************************************/

-- App_User: username, first_name, last_name, password, phone_number
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
insert into App_User values ('teo', 'Shawn', 'teo', 'teo', 12345678);
insert into App_User values ('Adiyogaisthebest', 'Adi', 'Yoga', 'password', 12345678);

-- Passenger: username
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
insert into Passenger values ('teo');
insert into Passenger values ('Adiyogaisthebest');

-- Driver: username, d_rating(NULL)
INSERT INTO Driver VALUES ('user1', NULL);
INSERT INTO Driver VALUES ('user2', NULL);
INSERT INTO Driver VALUES ('user3', NULL);
INSERT INTO Driver VALUES ('user4', NULL);
INSERT INTO Driver VALUES ('user5', NULL);
INSERT INTO Driver VALUES ('user6', NULL);
INSERT INTO Driver VALUES ('user7', NULL);
INSERT INTO Driver VALUES ('user8', NULL);
INSERT INTO Driver VALUES ('user9', NULL);
INSERT INTO Driver VALUES ('user10', NULL);
INSERT INTO Driver VALUES ('teo', NULL);
INSERT INTO Driver VALUES ('Adiyogaisthebest', NULL);

-- Car: plateNum, colors
INSERT INTO Car VALUES ('SFV7687J', 'White','Toyota',  5);
INSERT INTO Car VALUES ('S1', 'White','Honda', 5);
INSERT INTO Car VALUES ('EU9288C', 'Gray','Ferrari',2);
INSERT INTO Car VALUES ('AAA8888', 'Red','Lexus', 4);
INSERT INTO Car VALUES ('BBB8888', 'Black','Toyota',5);
INSERT INTO Car VALUES ('CCC8888', 'Blue','Range Rover', 4);
INSERT INTO Car VALUES ('007', 'Pink','Honda', 7);
INSERT INTO Car VALUES ('BC8888', 'Red','Honda', 7);
INSERT INTO Car VALUES ('C8888', 'Red','Lamborghini', 7);
INSERT INTO Car VALUES ('ABC8888', 'Red','Ferrari', 7);
INSERT INTO Car VALUES ('GiveMeA', 'Red','Ferrari', 7);

-- Promo: promoCode, quotaLeft, minPrice, disc
INSERT INTO Promo VALUES ('a1a', 10, 10, 20);
INSERT INTO Promo VALUES ('a1b', 1, 20, 20);
INSERT INTO Promo VALUES ('50OFF', 1, 100, 50);
INSERT INTO Promo VALUES ('40OFF', 1, 10, 40);
INSERT INTO Promo VALUES ('10OFF', 0, 20, 10);
INSERT INTO Promo VALUES ('20OFF', 5, 50, 20);
INSERT INTO Promo VALUES ('FREERIDE', 100, 0, 1000000);
INSERT INTO Promo VALUES ('ADIYOGA', 10, 10, 15);

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

-- Advertisement: timePosted(DEFAULT), driverID, numPass, departTime, price, to, from, ad_status
INSERT INTO Advertisement VALUES (TIMESTAMP '2019-10-10 12:30', 'user6', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Clementi', 'Pasir Ris', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2019-10-19 12:30', 'user9', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Changi Airport', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2019-10-20 12:30', 'user10', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user1', 2, TIMESTAMP '2019-12-12 12:34', 20, 'Joo Koon', 'Bendemeer', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user2', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Changi Airport', 'Paya Lebar', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user3', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Joo Koon', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user4', 2, TIMESTAMP '2019-12-12 12:34', 20, 'Kent Ridge', 'Changi Airport', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user5', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Changi Airport', 'Paya Lebar', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:30', 'user6', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-17 12:30', 'user7', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-18 12:30', 'user8', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-19 12:30', 'user9', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-20 12:30', 'user10', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-21 12:30', 'user10', 2, TIMESTAMP '2019-12-15 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:31', 'user1', 2, TIMESTAMP '2019-12-12 12:34', 20, 'Joo Koon', 'Bendemeer', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:31', 'user2', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Changi Airport', 'Paya Lebar', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:31', 'user3', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Joo Koon', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:31', 'user4', 2, TIMESTAMP '2019-12-12 12:34', 20, 'Kent Ridge', 'Changi Airport', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:31', 'user5', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Changi Airport', 'Paya Lebar', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-10 12:31', 'user6', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-17 12:31', 'user7', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-18 12:31', 'user8', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-19 12:31', 'user9', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-20 12:31', 'user10', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-21 12:31', 'Adiyogaisthebest', 2, TIMESTAMP '2019-12-12 12:30', 20, 'Jurong East', 'Pasir Ris', 'Active');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-22 12:31', 'Adiyogaisthebest', 2, TIMESTAMP '2019-12-13 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');
INSERT INTO Advertisement VALUES (TIMESTAMP '2018-12-23 12:31', 'Adiyogaisthebest', 2, TIMESTAMP '2019-12-14 12:30', 20, 'Jurong East', 'Pasir Ris', 'Scheduled');

-- Bids: passId, driverID, timePosted, price, status, numPass
INSERT INTO Bids VALUES ('user11', 'user3', TIMESTAMP '2018-12-10 12:30', 20, 'failed', 2);
INSERT INTO Bids VALUES ('user12', 'user3', TIMESTAMP '2018-12-10 12:30', 20, 'failed', 2);
INSERT INTO Bids VALUES ('user13', 'user3', TIMESTAMP '2018-12-10 12:30', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user11', 'user2', TIMESTAMP '2018-12-10 12:30', 20, 'ongoing', 2);
INSERT INTO Bids VALUES ('user14', 'user2', TIMESTAMP '2018-12-10 12:30', 20, 'ongoing', 2);
INSERT INTO Bids VALUES ('user15', 'user2', TIMESTAMP '2018-12-10 12:30', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user1', 'user6', TIMESTAMP '2018-12-10 12:30', 20, 'failed', 2);
INSERT INTO Bids VALUES ('user6', 'user5', TIMESTAMP '2018-12-10 12:30', 20, 'ongoing', 2);
INSERT INTO Bids VALUES ('user9', 'user4', TIMESTAMP '2018-12-10 12:30', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user7', 'user6', TIMESTAMP '2018-12-10 12:30', 50, 'successful', 2);
INSERT INTO Bids VALUES ('user12', 'user5', TIMESTAMP '2018-12-10 12:30', 20, 'ongoing', 2);
INSERT INTO Bids VALUES ('user3', 'user4', TIMESTAMP '2018-12-10 12:30', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user1', 'user4', TIMESTAMP '2018-12-10 12:30', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user8', 'user4', TIMESTAMP '2018-12-10 12:30', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user12', 'user7', TIMESTAMP '2018-12-17 12:30', 20, 'ongoing', 2);
INSERT INTO Bids VALUES ('user3', 'user8', TIMESTAMP '2018-12-18 12:30', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user12', 'user9', TIMESTAMP '2018-12-19 12:30', 20, 'successful', 2);
INSERT INTO Bids VALUES ('user3', 'user10', TIMESTAMP '2018-12-20 12:30', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user3', 'user10', TIMESTAMP '2018-12-21 12:30', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user10', 'user1', TIMESTAMP '2018-12-10 12:31', 20, 'successful', 2);
INSERT INTO Bids VALUES ('user9', 'user2', TIMESTAMP '2018-12-10 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user8', 'user3', TIMESTAMP '2018-12-10 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user7', 'user4', TIMESTAMP '2018-12-10 12:31', 20, 'successful', 2);
INSERT INTO Bids VALUES ('user6', 'user5', TIMESTAMP '2018-12-10 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user5', 'user6', TIMESTAMP '2018-12-10 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user4', 'user7', TIMESTAMP '2018-12-17 12:31', 20, 'successful', 2);
INSERT INTO Bids VALUES ('user3', 'user8', TIMESTAMP '2018-12-18 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user2', 'user9', TIMESTAMP '2018-12-19 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user1', 'user10', TIMESTAMP '2018-12-20 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user5', 'Adiyogaisthebest', TIMESTAMP '2018-12-21 12:31', 30, 'ongoing', 2);
INSERT INTO Bids VALUES ('user2', 'Adiyogaisthebest', TIMESTAMP '2018-12-22 12:31', 30, 'successful', 2);
INSERT INTO Bids VALUES ('user1', 'Adiyogaisthebest', TIMESTAMP '2018-12-23 12:31', 30, 'successful', 2);

-- Ride: rideID(NULL), passID, driverID, timePosted, status, p_rating, p_comment, d_rating, d_comment
INSERT INTO Ride VALUES(DEFAULT, 'user13', 'user3', TIMESTAMP '2018-12-10 12:30', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user7', 'user6', TIMESTAMP '2018-12-10 12:30', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user12', 'user9', TIMESTAMP '2018-12-19 12:30', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user3', 'user10', TIMESTAMP '2018-12-20 12:30', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user3', 'user10', TIMESTAMP '2018-12-20 12:30', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user10', 'user1', TIMESTAMP '2018-12-10 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user9', 'user2', TIMESTAMP '2018-12-10 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user8', 'user3', TIMESTAMP '2018-12-10 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user7', 'user4', TIMESTAMP '2018-12-10 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user6', 'user5', TIMESTAMP '2018-12-10 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user5', 'user6', TIMESTAMP '2018-12-10 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user4', 'user7', TIMESTAMP '2018-12-17 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user3', 'user8', TIMESTAMP '2018-12-18 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user2', 'user9', TIMESTAMP '2018-12-19 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user1', 'user10', TIMESTAMP '2018-12-20 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user2', 'Adiyogaisthebest', TIMESTAMP '2018-12-22 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
INSERT INTO Ride VALUES(DEFAULT, 'user1', 'Adiyogaisthebest', TIMESTAMP '2018-12-23 12:31', DEFAULT, DEFAULT, NULL, NULL, NULL, NULL);
UPDATE Ride SET p_rating = 5, p_comment = 'he was great' WHERE ride_id = 3;
UPDATE Ride SET d_rating = 5, d_comment = 'he was okay' WHERE ride_id = 3;
UPDATE Ride SET p_rating = 2, p_comment = 'he was noisy af' WHERE ride_id = 4;
UPDATE Ride SET d_rating = 4, d_comment = 'he was a good listener' WHERE ride_id = 4;
UPDATE Ride SET p_rating = 3, p_comment = 'this guy again...' WHERE ride_id = 5;
UPDATE Ride SET d_rating = 1, d_comment = 'this time he was not a good listener' WHERE ride_id = 5;
UPDATE Ride SET p_rating = 5, p_comment = 'would recommend' WHERE ride_id = 6;
UPDATE Ride SET d_rating = 5, d_comment = '10/10' WHERE ride_id = 6;
UPDATE Ride SET p_rating = 2, p_comment = 'he was quiet' WHERE ride_id = 7;
UPDATE Ride SET d_rating = 1, d_comment = 'he was driving recklessly!' WHERE ride_id = 7;
UPDATE Ride SET p_rating = 4, p_comment = 'good ride.' WHERE ride_id = 8;
UPDATE Ride SET d_rating = 1, d_comment = 'he was really nice' WHERE ride_id = 8;
UPDATE Ride SET p_rating = 3, p_comment = '3/5' WHERE ride_id = 9;
UPDATE Ride SET d_rating = 4, d_comment = 'he aite' WHERE ride_id = 9;
UPDATE Ride SET p_rating = 3, p_comment = 'he damn good' WHERE ride_id = 10;
UPDATE Ride SET d_rating = 5, d_comment = 'good' WHERE ride_id = 10;
UPDATE Ride SET p_rating = 3, p_comment = 'nahhhhh not good' WHERE ride_id = 11;
UPDATE Ride SET d_rating = 3, d_comment = 'nahhhhh not good too' WHERE ride_id = 11;
UPDATE Ride SET p_rating = 2, p_comment = 'would not recomment' WHERE ride_id = 12;
UPDATE Ride SET d_rating = 3, d_comment = 'it was fine' WHERE ride_id = 12;
UPDATE Ride SET p_rating = 4, p_comment = 'GOOD passenger' WHERE ride_id = 13;
UPDATE Ride SET d_rating = 1, d_comment = 'worse driver ever' WHERE ride_id = 13;
UPDATE Ride SET p_rating = 5, p_comment = 'As a passenger he was on time.' WHERE ride_id = 16;
UPDATE Ride SET d_rating = 5, d_comment = 'He was the best driver ever. Super nice!' WHERE ride_id = 16;
UPDATE Ride SET p_rating = 5, p_comment = 'Great' WHERE ride_id = 17;
UPDATE Ride SET d_rating = 5, d_comment = 'Driver nya ganteng sekali...' WHERE ride_id = 17;

-- Owns: driverID, plateNum
INSERT INTO Owns VALUES ('user1', 'SFV7687J');
INSERT INTO Owns VALUES ('user2', 'S1');
INSERT INTO Owns VALUES ('user3', 'EU9288C');
INSERT INTO Owns VALUES ('user4', 'AAA8888');
INSERT INTO Owns VALUES ('user5', 'BBB8888');
INSERT INTO Owns VALUES ('user6', 'CCC8888');
INSERT INTO Owns VALUES ('user7', 'CCC8888');
INSERT INTO Owns VALUES ('user8', 'BC8888');
INSERT INTO Owns VALUES ('user9', 'C8888');
INSERT INTO Owns VALUES ('user10', 'ABC8888');
INSERT INTO Owns VALUES ('teo', '007');
INSERT INTO Owns VALUES ('Adiyogaisthebest', 'GiveMeA');


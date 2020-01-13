<div style="height: 29.7cm; width: 21cm; text-align: center;">
    <h1>
        CS2102 - GROUP 26
    </h1>
    <br>
    <div style="font-size:2rem; padding-bottom:1rem;">
        TumpangMePlease 
        <br>
        <br>
        <br>
        <br>
        A CarPooling App
        <br>
        <br>
        <img src="https://i.imgur.com/iCxmJXZ.jpg">
        </img>
    </div>
    <h3 style="text-align: right">
        <div style="font-weight:bold; font-size:2rem;">Team:</div>
        <br>
        James Pang Mun Wai - A0169761R
        <br>
        <br>
        Jin Shuyuan - A0162475B
        <br>
        <br>
        Lee Jin Yao - A0168574N
        <br>
        <br>
        Teo Xuan Wei - A0168645R
    </h3>
</div>

# Introduction
## Project Description
This is a carpooling application which allows car drivers to advertise opportunities for carpooling and passengers to search for car rides. 

Drivers can create an advertisement that specifies the locations to pick and drop  a passenger. Other users can then bid for the desired advertisements. Passengers can then bid for the rides. The successful bidder for an advertisement can be chosen by the car driver or automatically allocated by the system based on some criteria. 

Each user can be both a passenger and a driver, and users will need to create an account in order to use the app.

## Project Responsibilities
| Member | Contributions |
| -------- | -------- |
| James Pang Mun Wai | <ul><li>Setup and designed the entire front-end of the web application</li><li>Implemented both front-end and back-end functionalities for payment page, promo code, profile page, home page, bidding and reviewing</li><li>Constant checking of web application to ensure that it is bug free</li><li>Added dummy SQL data</li><li>Schedule weekly meetings, set agendas, delegate tasks to teammates and ensure team's progress</li><li>Complex query and functionality for system auto selection of winning bid</li><li>Complex query and functionality for best promo code suggestion</li><li>Verifying whether decomposed tables are in BCNF</li></ul>|
| Jin Shuyuan | <ul><li>Add triggers, procedures and functions into SQL file</li><li>Implement back-end functionality of car registration page</li><li>Implement back-end functionality of create advertisement page</li><li>Link front-end display with back-end functionality of car registration page</li><li>Link front-end display with back-end functionality of create advertisement page</li><li>Modify front-end display of home page</li><li>Verifying whether decomposed tables are in BCNF</li></ul> |
| Lee Jin Yao | <ul><li>Translate ER diagram to SQL tables and populated sample data</li><li>Implemented search functionalities to filter advertisements based on destination locations</li><li>Implemented bid functionality for passengers</li><li>Implemented upcoming driver pick-ups</li><li>Implemented driver updating ride status</li><li>Conducted system test on app to weed out bugs and fixed them</li></ul> |
| Teo Xuan Wei |<ul><li>Translate ER diagram to SQL tables</li><li>Link view advertisement page to backend database</li><li>Link view advertisement page to backend database</li><li>Modify front-end display of view advertisement page to ensure buttons perform relevant queries</li><li>Include checks to ensure only active advertisements and bids are shown on the front-end</li><li>Modify presentable ER diagram using Lucid-chart</li></ul>|
| Entire Team | <ul><li>Designed the ER Diagram</li><li>Made decisions on the constraints</li><li>Report and Documentation</li></ul>|
## Software Tools and Frameworks
### Front-end
- Bootstrap 
- JQuery
- HTML, CSS, JavaScript
### Back-end
- Python Flask
- PostgreSQL Database

# Database Design
## Application Requirements and Constraints
### Relationships & Participation Constraints

* Advertisement constraints:
  * Each advertisement can be created by exactly one  ( = 1) driver
  * Each advertisement can go from exactly one ( = 1) Place
  * Each advertisement can go to exactly one ( = 1) Place

* Bid constraints:
  * Each bid can schedule for at most one ( <= 1) ride
* Ride constraints:
  * Each ride can be scheduled by exactly one ( = 1) bid
* Promo code constraints:
  * Each passenger can redeem at most one ( <= 1) promo for each ride
* Driver and car constraints:
  * Each driver owns at least one ( >= 1) car
  * Each car is owned by at least one ( >= 1) driver

* AppUser (satisfies both overlapping and covering constraints):
  * Each user can be both driver and passenger.
  * Each user must be either driver, passenger, or both.

### Requirements
1) When creating an advertisement, the earliest departure time must be at least an hour after the date of posting the advertisement.
2) A user can create/amend bids up to 30 minutes before the scheduled departure time.
3) When it is exactly 30 minutes before the departure time, the system should execute `system auto selection` to select the winning bid based on a certain criteria. We currently simulate this functionality as a button to press instead of a timer that constantly checks for any advertisement that is expiring.
4) A user cannot be a driver unless he/she has registered for at least one car.
5) A passenger cannot bid with a price lower than the minimum price stated for the advertisement.
6) A driver cannot bid for his/her own advertisement.
7) A promo cannot be redeemed if its max quota is reached.
8) Every new bid by a passenger for the same advertisement must be greater than or equal to his/her old bid.
9) When an advertisement is deleted, all the bids for that advertisement will be default to `failed` bid.
10) When a winning bid is chosen for an advertisement, all other bids for that advertisement will be default to `failed` bid.
11) To ensure that the passenger pays for his successful ride, he/she will always be redirected to the payment page and will not be able to access any other functionalities until he/she makes the necessary payment.

## Entity-Relationship Diagram
![](https://i.imgur.com/UVnjmct.png)

### Justification for usage of serial id in Ride table
The initial plan was to have Ride as a weak entity set to the Bids aggregation. However, having it as a weak entity set meant that it would be a many-to-one relationship: multiple rides to one bid. This was not what we aim to model as only the successful bid amongst the rest (at most one), will be scheduled as a ride. Hence for simplicity's sake, we decided to use a serial id `ride_id` as the primary key for identifying every successfully scheduled ride.

## Relational Schema

### Entity Tables
```sql
CREATE TABLE App_User (
    username     varchar(50) PRIMARY KEY,
    first_name   varchar(20) NOT NULL,
    last_name    varchar(20) NOT NULL,
    password     varchar(50) NOT NULL,
    phone_number varchar(20) NOT NULL
);

CREATE TABLE Driver (
    username varchar(50) PRIMARY KEY REFERENCES App_User ON DELETE CASCADE,
    d_rating NUMERIC
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
    promo_code   varchar(20) PRIMARY KEY,
    max_quota    INTEGER NOT NULL,
    min_price    INTEGER,
    discount     INTEGER NOT NULL
);

CREATE TABLE Place (
    name varchar(50) PRIMARY KEY
);

CREATE TABLE Advertisement (
    time_posted       TIMESTAMP   DEFAULT date_trunc('second', 
                                                     current_timestamp),
    driver_ID         varchar(50) REFERENCES Driver ON DELETE CASCADE,
    num_passengers    INTEGER     NOT NULL,
    departure_time    TIMESTAMP   NOT NULL,
    price             INTEGER     NOT NULL, -- minimum bidding price
    to_place          varchar(50) NOT NULL REFERENCES Place,
    from_place        varchar(50) NOT NULL REFERENCES Place,
    ad_status         varchar(20) NOT NULL,
    PRIMARY KEY (time_posted, driver_ID),
    CHECK       (num_passengers > 0),
    CHECK       (ad_status = 'Active' OR ad_status = 'Scheduled' OR 
                 ad_status = 'Deleted')
);

CREATE TABLE Ride (
    ride_ID        SERIAL      PRIMARY KEY,
    passenger_ID   varchar(50) NOT NULL,
    driver_ID      varchar(50) NOT NULL,
    time_posted    TIMESTAMP   NOT NULL,
    status         varchar(20) DEFAULT 'pending',
    is_paid        BOOLEAN NOT NULL DEFAULT false,
    p_comment      varchar(50),
    p_rating       numeric,
    d_comment      varchar(50),
    d_rating       numeric,
    FOREIGN KEY (passenger_ID, time_posted, driver_ID) REFERENCES Bids,
    CHECK (status = 'pending' OR status = 'ongoing' OR status = 'completed')
);
```

### Relationship Tables
```sql
CREATE TABLE Bids (
    passenger_ID     varchar(50) REFERENCES Passenger ON DELETE CASCADE,
    driver_ID        varchar(50) REFERENCES Driver    ON DELETE CASCADE,
    time_posted      TIMESTAMP	 DEFAULT date_trunc('second', 
                                                   current_timestamp),
    price            NUMERIC,
    status           varchar(20),
    no_passengers    INTEGER,
    PRIMARY KEY (passenger_ID, time_posted, driver_ID),
    CHECK       (passenger_ID <> driver_ID),
    CHECK       (status = 'ongoing' OR status = 'successful' OR 
                 status = 'failed'),
    CHECK       (price > 0)
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
```

### Normal Forms

All the tables are in BCNF.

The following table lists all the attribute mappings in the ER diagram:
| Attributes    | Simplified Attributes| 
| ------------- |:-------------:| 
| username     | A| 
| first_name     | B     |   
| last_name | C     |   
|password|D|
|phone_number|E|
|p_rating (Passenger)|F|
|price|G|
|no_passengers (Bids)|H|
|status|I|
|no_passengers (Advertisement)|J|
|ad_status|K|
|time_posted|L|
|departure_time|M|
|price|N|
|d_rating (Driver)|O|
|colour|P|
|no_passengers (Car)|Q|
|brand|R|
|plate_number|S|
|name|T|
|ride_ID|U|
|is_paid|V|
|status|W|
|d_rating (Ride)|X|
|d_comment|Y|
|p_comment|Z|
|p_rating (Ride)|À|
|min_price|È|
|discount|Ì|
|max_quota|Ò|
|promo_code|Ù|



Non-trivial Functional Dependencies from ER Diagram:
AppUser: A -> BCDE
Passenger: A -> F
Driver: A -> O
Car: S -> RPQ
Promo: Ù -> ÈÌÒ
Ride: U -> VWXYZÀ
Advertisement: AL -> JKMN
Bids: AL -> GHI

FDs = { A -> BCDE; A -> F; A -> O; S -> RPQ; Ù -> ÈÌÒ; U -> VWXYZÀ; AL -> JKMN; AL -> GHI }

| Table   | Projection| 
| ------------- |:-------------:| 
| AppUser: R1(<u>A</u>,B,C,D,E)| { A -> BCDE }| 
| Passenger: R2(<u>A</u>,F)| { A -> F }| 
| Driver: R3(<u>A</u>,O)| { A -> O }| 
| Car: R4(<u>S</u>,R,P,Q)| { S -> RPQ }| 
| Promo: R5(<u>Ù</u>,È,Ì,Ò)| { Ù -> ÈÌÒ }| 
| Ride: R6(<u>U</u>,V,W,X,Y,Z,À)| { U -> VWXYZÀ }| 
| Advertisement: R7(<u>A,L</u>,M,N,K,J)| { AL -> JKMN }| 
| Bids: R8(<u>A,L</u>,G,H,I)| { AL -> GHI }| 

None of the non-trivial FDs in projected FDs violate BCNF.
Thus, all the decomposed tables are in BCNF.




## Non-trivial Constraints Enforced By Triggers
### Ensuring bid price to be higher than previous bids
We placed a constraint on the bids where further bids on the same advertisement must have a higher price.
```sql
CREATE OR REPLACE FUNCTION update_bid_failed()
RETURNS TRIGGER AS $$ BEGIN
RAISE NOTICE 'New bid price should be higher'; RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER bid_update_trig
BEFORE UPDATE ON bids FOR EACH ROW
WHEN (NEW.price < OLD.price)
EXECUTE PROCEDURE update_bid_failed();
```
### Updating the average rating of passengers and drivers
The current implementation of getting the average rating for each passenger is the average rating across all rides that he/she participated. The rating is given after the ride has been created, hence the passenger rating is added to that ride by using the `UPDATE` operation. Hence, we enforced the automatic calculation of the passenger's average rating with the following trigger:

```sql
CREATE OR REPLACE FUNCTION
update_passenger_average_rating() RETURNS TRIGGER AS
$tag$
DECLARE average_rating numeric;
BEGIN
RAISE NOTICE 'Updating Average Passenger Rating';
SELECT ROUND(SUM(p_rating) / COUNT(*), 2) INTO average_rating FROM Ride 
WHERE passenger_id = OLD.passenger_id AND p_rating IS NOT NULL;

UPDATE Passenger SET p_rating = average_rating 
WHERE username = NEW.passenger_id;
RETURN NEW;
END;
$tag$
LANGUAGE plpgsql;

CREATE TRIGGER update_passenger_ride_rating
AFTER UPDATE ON ride FOR EACH ROW
WHEN ((OLD.p_rating <> NEW.p_rating OR OLD.p_rating IS NULL) AND 
       NEW.p_rating IS NOT NULL)
EXECUTE PROCEDURE update_passenger_average_rating();
```

A similar trigger is also created to compute the average rating of drivers.

#### Justification of using triggers instead of computing the average rating when needed
We noticed that there's another simpler solution by just querying and computing the average rating for a specific passenger whenever needed. However, the reason behind implementing this as a trigger as opposed the simpler solution is because the average rating is constantly needed in functionalities such as `system auto selection of winning bid`, `viewing of passenger profile` and `driver's list of bids for his advertisements`. Hence, the simpler solution will be more computationally expensive as it requires to go through the Rides table each time the average rating of passengers is required.

## Chained triggers
### Chained trigger 1: Set the status of Advertisement to `Scheduled` upon successful bid
When a bid has been succesfully selected by the system or the driver, the status of relevant advertisement will be changed to `scheduled`. This operation has to be enforced via a trigger and the implementation is as follows:
```sql
CREATE OR REPLACE FUNCTION update_ad_bid_on_successful_bid()
RETURNS TRIGGER AS $$ BEGIN
    RAISE NOTICE 
    'Updating advertisement for % % to Scheduled after a successful bid'
    , NEW.driver_ID, NEW.time_posted;
    UPDATE Advertisement a SET ad_status = 'Scheduled'
        WHERE (a.time_posted, a.driver_ID) = (NEW.time_posted, NEW.driver_ID);
    RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER update_advertisement_on_successful_bid
AFTER UPDATE ON Bids FOR EACH ROW
WHEN (OLD.status = 'ongoing' AND NEW.status = 'successful')
EXECUTE PROCEDURE update_ad_bid_on_successful_bid();
```
### Chained trigger 2: Set all bids to `failed` status when status of Advertisement changes
When a specific advertisement is deleted or scheduled upon selecting a successful bid, all bids targeted to that advertisement should be set to a status of `failed`, apart from the successful bid. We enforce this by using the following trigger:
```sql
CREATE OR REPLACE FUNCTION update_bid_status_to_fail()
RETURNS TRIGGER AS $$ BEGIN
    RAISE NOTICE 
    'Updating all non-winning bids for % % to failed',
    NEW.driver_ID, NEW.time_posted;
    UPDATE Bids AS b SET status = 'failed' 
    WHERE (b.time_posted, b.driver_ID) 
    = (NEW.time_posted, NEW.driver_ID) AND b.status = 'ongoing';
    RETURN NULL;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER update_ad_status
AFTER UPDATE ON Advertisement FOR EACH ROW
WHEN (NEW.ad_status = 'Deleted' OR NEW.ad_status = 'Scheduled')
EXECUTE PROCEDURE update_bid_status_to_fail();
```


## Complex Queries
### System's auto selection of winning bid
Instead of drivers manually accepting the winning bid based on his/her preference, the winning bid will be automatically chosen by the `system auto selection` functionality that is based on the following order by decreasing priority:
1.  highest bid price
2.  highest passenger rating
3.  highest number of completed rides
4.  if there is still a tie, the winning bid is chosen based on their ascending order of username, alphabetically

```sql
-- SELECT passenger with best bid
WITH MaxRides AS
(SELECT COUNT(*) as count 
FROM Bids B1 JOIN Ride R1 
    ON B1.passenger_id = R1.passenger_id
WHERE B1.driver_id = {{ driver_id }} AND 
      B1.time_posted = {{ time_posted }} AND 
      R1.status = 'completed' 
GROUP BY R1.passenger_id
),
BidStatistics AS
(SELECT B.passenger_id, CASE
	WHEN (price = (SELECT MAX(price) FROM Bids 
                   WHERE driver_id = {{ driver_id }} AND 
                         time_posted = {{ time_posted }}))
THEN 1	
ELSE 0 
END AS max_price, -- highest price

CASE
WHEN ((SELECT p_rating FROM Passenger WHERE username =  B.passenger_id) 
       = 
      (SELECT max(p_rating) FROM Bids NATURAL JOIN Passenger 
       WHERE driver_id = {{ driver_id }} AND 
             time_posted = {{ time_posted }}))
THEN 1	
ELSE 0	
END AS max_passenger_rating, -- highest rating

CASE
WHEN ((SELECT COUNT(*) FROM Ride R 
       WHERE R.passenger_id = B.passenger_id AND status = 'completed') 
       = 
      (SELECT MAX(count) FROM MaxRides))
THEN 1  
ELSE 0  
END AS max_passenger_rides -- highest number of rides

FROM Bids B 
WHERE driver_id = {{ driver_id }} AND time_posted = {{ time_posted }}
)
SELECT BS1.passenger_id FROM BidStatistics BS1
WHERE NOT EXISTS (
    SELECT 1 FROM BidStatistics BS2
    WHERE (BS2.max_price > BS1.max_price) 
       OR (BS2.max_price = BS1.max_price AND 
           BS2.max_passenger_rating > BS1.max_passenger_rating) 
       OR (BS2.max_price = BS1.max_price AND 
           BS2.max_passenger_rating = BS1.max_passenger_rating AND 
           BS2.max_passenger_rides > BS1.max_passenger_rides)
)
ORDER BY BS1.passenger_id ASC;
```
Note: If there are no bids for the particular advertisement, the advertisement will have a status of `failed`.

### Getting the list of advertisements available
Only list of active advertisements that are at least 30 mins before their departure time will be retrieved with their details such as time remaining to bid and maximum bidding price. The user's own listed advertisements will not be shown.
```sql
SELECT a.time_posted::timestamp(0) AS date_posted, 
       a.departure_time::timestamp(0) AS departure_time,
       a.driver_id, 
       (SELECT d_rating FROM Driver WHERE username = a.driver_id), 
       a.from_place, a.to_place, a.num_passengers, a.price,
       (SELECT max(price) FROM bids b 
        WHERE b.time_posted = a.time_posted AND 
              b.driver_id = a.driver_id) AS highest_bid,
       (SELECT COUNT(*) FROM bids b 
        WHERE b.time_posted = a.time_posted AND 
              b.driver_id = a.driver_id) AS num_bidders,
       (a.departure_time::timestamp(0) - CURRENT_TIMESTAMP::timestamp(0) - 
           '30 minutes'::interval) AS time_remaining
FROM advertisement a 
WHERE a.departure_time > (CURRENT_TIMESTAMP + '30 minutes'::interval) AND 
      ad_status = 'Active' and a.driver_id <> {{ username }} 
```

### Suggestion of the best promo code for current payment
The best promo code that will be suggested to the user will be based on:
1. The highest discount w.r.t the current payment price (e.g. if payment price is $40, and the promo code discounts $50, then the discount w.r.t the current price is $40)
2. The smallest discount price of the promo code
3. The most number of quota left for the promo code
4. If there is still a tie, the best promo is chosen based on the ascending order of promo_code, alphabetically

There are additional constraints where the quota of the promo code must not be used up and the bidded price must be higher than the minimum price of promo in order to use the promo code.
```sql
WITH MostDiscountedAndAvailablePromos AS (
SELECT p.promo_code, p.discount, 
       (p.max_quota - (SELECT COUNT(*) FROM Redeems r 
                       WHERE r.promo_code = p.promo_code)) AS amount_left
FROM Promo p
WHERE p.min_price <= {{ bid_price }} AND
      p.max_quota > 
          (SELECT COUNT(*) FROM Redeems r 
           WHERE r.promo_code = p.promo_code AND 
                (
                 p.discount = (SELECT MAX(p1.discount) FROM Promo p1) OR 
                    (p.discount >= {{ bid_price }})
                )
           )
),
PromoStatistics AS (
	SELECT *, CASE 
	WHEN (discount = (SELECT MIN(discount) 
                          FROM MostDiscountedAndAvailablePromos)) 
        THEN 1 ELSE 0 END AS is_least_discount
	FROM MostDiscountedAndAvailablePromos 
)
SELECT PS1.promo_code, PS1.discount FROM PromoStatistics PS1
WHERE NOT EXISTS (
	SELECT 1 FROM PromoStatistics PS2
  	WHERE (PS2.is_least_discount > PS1.is_least_discount) OR 
              (PS2.is_least_discount = PS1.is_least_discount AND 
                   PS2.amount_left > PS1.amount_left)
)
ORDER BY PS1.promo_code ASC
```

# Web Page Design and Functionality

## Home Page
### Description:
This page is the default page every user will see after a successful login. As show in figure below, it has three main functions:
1) search bar to filter down advertisements with searched destination.
2) list of currently active advertisements available for bidding.
3) list of advertisements that user has bidded for, along with the bid status (`failed`, `success`, `ongoing`).

![](https://i.imgur.com/wmWEUgz.jpg)

## Share A Ride Page
### Description:
This page is designed for users (who are drivers) to be able to share their ride advertisements. The page will first check for the two criterias:
1) User is a driver
2) Driver has registered a car

If both criterias are met, the user will be able to fill up a form with the relevant basic information (as shown in figure below) required for the advertisement to be listed on the home page. Else, the user will be redirected to the car registration page.

Upon a successful creation of advertisement, the advertisement will be available on the home page for passengers to bid. Advertisements can be deleted in the following page.

![](https://i.imgur.com/rRDniII.jpg)

## Advertisement Management Page
### Description:
This page is designed for users (who are drivers) to be able to view and manage advertisements they posted previously. It is personal and unique to each user unlike the home page which is a general page that is common for all users. As show in figure below, there are two lists on this page:
1) List of advertisements posted by the driver
2) List of bids passengers placed for all advertisements

![](https://i.imgur.com/4JokrfU.jpg)

On this page, the driver can choose to delete a previously posted advertisement, or accept a bid of his choice. Upon accepting a bid, the advertisement will be taken down from the driver's list of advertisements and from the home page. A new ride will then be scheduled and will appear in the following page.

Additional features:
The `System Accept` button is a simulation of an automated system selection for demonstration purposes. It simulates an automatic selection done by the system when the system detects that the time is up (30 mins before scheduled time to leave). 

The system will allocate the winning bid based on the following descending order of priority:
1.  highest bid price
2.  highest passenger rating
3.  highest number of completed rides at the point of query
4.  if there is still a tie, the winning bid is chosen based on their ascending order of username, alphabetically


## Scheduled Page
### Description:
This page shows a list of  upcoming rides scheduled for the user (passenger) upon a successful bid. If the user is a driver, he/ she will be able to see an addition list of upcoming pick-ups.
Besides the two lists, there are three types of buttons on this page:
1) **Review:** for passenger/ driver to rate the other party.
2) **Pay:** for passenger to pay before, during or after the ride.
3) **Pick-up/Drop off:** for driver to indicate the start and end of the ride.

![](https://i.imgur.com/ancb8Zk.jpg)

## Payment Page
### Description:
The following page shows the payment page where passengers are able to pay for their scheduled rides. There will be a message on suggesting the promo code available with the best rebates for the passenger to apply.

![](https://i.imgur.com/5pchNkl.jpg)


### Additional features:
If the ride has ended and the passenger have not paid, all buttons and actions will redirect user to the payment page so that user cannot access any other functionality before he/she pays.


# Summary
## Difficulties Faced
- Finalizing entity/ relationship sets and ER diagram in the initial phase of the project as it took several iterations before we understood the project requirements and came out with a suitable ER diagram
- Making sure the features of the app are cohesive and match the design requirements
- As some of us had no experience with front-end development, we took significant time to learn and get started with Python Flask and in particular, how to parse the data between front-end and back-end
- Finding and taking the time to discuss as a team proved to be challenging as everyone had other academic commitments

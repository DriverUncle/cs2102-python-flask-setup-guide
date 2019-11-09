from flask import Blueprint, redirect, render_template, request
from flask_login import current_user, login_required, login_user, logout_user

from __init__ import db, login_manager
from forms import LoginForm, RegistrationForm, BidForm
from models import AppUser


def getExistingBid(passenger_id, time_posted, driver_id):
    query = "SELECT * FROM Bids WHERE (passenger_id, time_posted, driver_id) = " \
            "('{}', '{}', '{}');".format(passenger_id, time_posted, driver_id)
    result = db.session.execute(query).fetchone()
    print('existing result: ', result)

    return result


def makeBid(passenger_id, time_posted, driver_id, price, numPassengers):
    query = None
    existing_bid = getExistingBid(passenger_id, time_posted, driver_id)
    if existing_bid:
        print(existing_bid[3])
        prev_bid_price = existing_bid[3]
        if prev_bid_price > float(price):
            return "Your bid price must be higher than the previous bid of {}!".format(prev_bid_price)
        else:
            query = "UPDATE Bids SET Price = {}, no_passengers = {} " \
                    "WHERE (passenger_id, time_posted, driver_id) = ('{}', '{}', '{}');".format(round(float(price), 2),
                                                                                                numPassengers, passenger_id,
                                                                                                time_posted, driver_id)
    else:
        query = "INSERT INTO bids(passenger_id, driver_id, time_posted, price, status, no_passengers) " \
                "VALUES ('{}', '{}', '{}', '{}', 'ongoing', '{}');".format(current_user.username, driver_id,
                                                                           time_posted, round(float(price), 2),
                                                                           numPassengers)
    # print(query)
    db.session.execute(query)
    db.session.commit()

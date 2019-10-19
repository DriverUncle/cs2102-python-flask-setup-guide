from flask import Blueprint, redirect, render_template, request
from flask_login import current_user, login_required, login_user, logout_user

from __init__ import db, login_manager
from forms import LoginForm, RegistrationForm, BidForm
from models import AppUser

# Returns true if there's existing bid; false otherwise.
def hasExistingBid(passenger_id, time_posted, driver_id):
    query = "SELECT * FROM Bids WHERE (passenger_id, time_posted, driver_id) = "\
        "('{}', '{}', '{}');".format(passenger_id, time_posted, driver_id)
    result = db.session.execute(query).fetchone()
    print('existing result: ', result)

    return False if result is None else True

def makeBid(passenger_id, time_posted, driver_id, price, numPassengers):
    query = None
    if hasExistingBid(passenger_id, time_posted, driver_id):
        query = "UPDATE Bids SET Price = {}, no_passengers = {} WHERE (passenger_id, time_posted, driver_id) = "\
            "('{}', '{}', '{}');".format(price, numPassengers, passenger_id, time_posted, driver_id)
    else:
        query = "INSERT INTO bids(passenger_id, driver_id, time_posted, price, status, no_passengers) " \
            "VALUES ('{}', '{}', '{}', '{}', 'ongoing', '{}')".format(current_user.username, driver_id,
            time_posted, price, numPassengers)
    print(query)
    db.session.execute(query)
    db.session.commit()

def deleteBid():
    pass

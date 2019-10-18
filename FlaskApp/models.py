from __init__ import db


class AppUser(db.Model):
    username = db.Column(db.String, primary_key=True)
    first_name = db.Column(db.String, nullable=False)
    last_name = db.Column(db.String, nullable=False)
    password = db.Column(db.String, nullable=False)
    phone_number = db.Column(db.String, nullable=False)

    def is_authenticated(self):
        return True

    def is_active(self):
        return True

    def is_anonymous(self):
        return False

    def get_id(self):
        return self.username


class Advertisement(db.Model):
    time_posted = db.Column(db.String, primary_key=True)
    driver_id = db.Column(db.String, primary_key=True)
    num_passengers = db.Column(db.String, nullable=False)
    departure_time = db.Column(db.String, nullable=False)
    price = db.Column(db.String, nullable=False)
    to_place = db.Column(db.String, nullable=False)
    from_place = db.Column(db.String, nullable=False)


class Bids(db.Model):
    passenger_id = db.Column(db.String, primary_key=True)
    driver_id = db.Column(db.String, primary_key=True)
    time_posted = db.Column(db.String, primary_key=True)
    price = db.Column(db.String, nullable=False)
    status = db.Column(db.String)
    no_passengers = db.Column(db.String, nullable=False)


class Driver(db.Model):
    username = db.Column(db.String, primary_key=True)
    d_rating = db.Column(db.String)

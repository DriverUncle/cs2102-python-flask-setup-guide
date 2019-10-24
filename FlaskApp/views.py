from flask import Blueprint, redirect, render_template, request
from flask_login import current_user, login_required, login_user, logout_user

from __init__ import db, login_manager
from forms import LoginForm, RegistrationForm, BidForm, PaymentForm
from models import AppUser, Driver

from bidManager import makeBid
from scheduleManager import getUpcomingPickups, isDriver

view = Blueprint("view", __name__)


@login_manager.user_loader
def load_user(username):
    user = AppUser.query.filter_by(username=username).first()
    return user or current_user


@view.route("/", methods=["GET", "POST"])
def render_home_page():
    if current_user.is_authenticated:

        ad_list_query = "SELECT a.time_posted::timestamp(0) as date_posted, a.departure_time::timestamp(0) as departure_time, " \
                        "a.driver_id, a.from_place, a.to_place, a.num_passengers," \
                        "(SELECT max(price) from bids b where b.time_posted = a.time_posted and b.driver_id = a.driver_id) as highest_bid," \
                        "(SELECT count(*) from bids b where b.time_posted = a.time_posted and b.driver_id = a.driver_id) as num_bidders," \
                        "(a.departure_time::timestamp(0) - CURRENT_TIMESTAMP::timestamp(0) - '30 minutes'::interval) as time_remaining" \
                        " from advertisement a where a.departure_time > (CURRENT_TIMESTAMP + '30 minutes'::interval)"
        ad_list = db.session.execute(ad_list_query).fetchall()

        bid_list_query = "select a.time_posted::timestamp(0) as date_posted, a.departure_time::timestamp(0) as departure_time, " \
                         "a.driver_id, a.from_place, a.to_place, b.no_passengers, b.price as bid_price, b.status " \
                         "from advertisement a JOIN bids b ON a.driver_id = b.driver_id and a.time_posted = b.time_posted " \
                         "where " \
                         "b.passenger_id= '{}'".format(current_user.username)
        bid_list = db.session.execute(bid_list_query).fetchall()

        # Bid form handling
        form = BidForm()
        form.no_passengers.errors = ''
        form.no_passengers.errors = ''
        if form.is_submitted():
            price = form.price.data
            no_passengers = form.no_passengers.data
            time_posted = form.hidden_dateposted.data
            driver_id = form.hidden_did.data
            if form.validate_on_submit():
                # disallow bidding to own-self's advertisement
                if int(no_passengers) > int(form.hidden_maxPax.data):
                    form.no_passengers.errors.append(
                        'Max number of passengers allowed should be {}.'.format(form.hidden_maxPax.data))
                else:
                    makeBid(current_user.username, time_posted, driver_id, price, no_passengers)
                    return redirect("/")

        return render_template("home.html", form=form, current_user=current_user, ad_list=ad_list, bid_list=bid_list)
    else:
        return redirect("/login")


@view.route("/registration", methods=["GET", "POST"])
def render_registration_page():
    form = RegistrationForm()
    if form.validate_on_submit():
        username = form.username.data
        first_name = form.first_name.data
        last_name = form.last_name.data
        password = form.password.data
        phone_num = form.phone_number.data
        query = "SELECT * FROM app_user WHERE username = '{}'".format(username)
        exists_user = db.session.execute(query).fetchone()
        if exists_user:
            form.username.errors.append("{} is already in use.".format(username))
        else:
            query = "INSERT INTO app_user(username, first_name, last_name, password, phone_number) " \
                    "VALUES ('{}', '{}', '{}', '{}', '{}')" \
                .format(username, first_name, last_name, password, phone_num)
            db.session.execute(query)
            db.session.commit()

            query = "INSERT INTO passenger(username, p_rating) VALUES('{}', NULL)".format(username)
            db.session.execute(query)
            db.session.commit()

            form.message = "Register successful! Please login with your newly created account."
    return render_template("registration.html", form=form)


@view.route("/logout")
def logout():
    logout_user()
    return redirect("/login")


@view.route("/login", methods=["GET", "POST"])
def render_login_page():
    form = LoginForm()
    if form.is_submitted():
        print("username entered:", form.username.data)
        print("password entered:", form.password.data)
        print(form.validate_on_submit())
    if form.validate_on_submit():
        user = AppUser.query.filter_by(username=form.username.data).first()
        if user:
            # TODO: You may want to verify if password is correct
            if user.password == form.password.data:
                login_user(user)
                return redirect("/")
            else:
                form.password.errors.append("Wrong password!")
        else:
            form.username.errors.append("No such user! Please login with a valid username or register to continue.")
    return render_template("index.html", form=form)


@view.route("/scheduled", methods=["GET"])
def render_scheduled_page():
    if not current_user.is_authenticated:
        return redirect("/login")

    upcoming_rides_query = "SELECT r.ride_id, r.time_posted, a.departure_time, a.from_place, a.to_place, " \
                            "r.driver_id, o.plate_number, a_u.phone_number, r.status, r.is_paid FROM Ride r" \
                            " INNER JOIN " \
                            "Advertisement a " \
                            "ON r.time_posted = a.time_posted and r.driver_id = a.driver_id" \
                            " INNER JOIN " \
                            "Owns o " \
                            "ON r.driver_id = o.driver_id " \
                            " INNER JOIN " \
                            "app_user a_u " \
                            "ON r.driver_id = a_u.username " \
                            "WHERE r.passenger_id = '{}'".format(current_user.username)
    upcoming_rides = db.session.execute(upcoming_rides_query).fetchall()
    print(upcoming_rides)
    return render_template("scheduled.html", current_user=current_user, upcoming_rides=upcoming_rides,\
        upcoming_pickups=getUpcomingPickups(current_user.username), is_driver=isDriver(current_user.username))


@view.route("/car-registration", methods=["GET", "POST"])
def render_car_registration_page():
    if current_user.is_authenticated:
        if request.method == "POST":
            brand = request.form['brand']
            plate_num = request.form['plate-num']
            no_passenger = request.form['no_passengers']
            color = request.form['colour']
            if (brand == "" or plate_num == "" or color == ""):
                # input fields are empty
                return render_template("car-registration.html", current_user=current_user, empty_error=True)
            elif(int(no_passenger) <= 0):
                return render_template("car-registration.html", current_user=current_user, negative_passenger_error=True)
            else:
                check_car_query = "SELECT * FROM car WHERE car.plate_number = '{}';".format(plate_num)
                check_car = db.session.execute(check_car_query).fetchall()
                if (len(check_car) != 0):
                    # car exists in DB
                    # check whether 2 cars are the same
                    existing_car_colour = check_car[0][1]
                    existing_car_brand = check_car[0][2]
                    existing_car_passenger = check_car[0][3]
                    if (existing_car_brand != brand or int(existing_car_passenger) != int(no_passenger) or existing_car_colour != color):
                        return render_template("car-registration.html", current_user=current_user,
                                               not_same_car_error=True)
                    else:
                        # same car as in DB
                        # insert into driver
                        add_driver_query = "CALL add_driver('{}');".format(current_user.username)
                        db.session.execute(add_driver_query)
                        # insert into owns
                        add_owns_query = "CALL add_owns('{}', '{}');".format(current_user.username, plate_num)
                        db.session.execute(add_owns_query)
                        db.session.commit()
                        return render_template("car-registration.html", current_user=current_user, success=True)

                else:
                    # car doesn't exist in DB
                    # insert a car
                    add_car_query = "INSERT INTO car(plate_number, colour, brand, no_passengers) " \
                        "VALUES ('{}','{}','{}','{}');".format(plate_num, color, brand, no_passenger)
                    db.session.execute(add_car_query)
                    # insert into driver
                    add_driver_query = "CALL add_driver('{}');".format(current_user.username)
                    db.session.execute(add_driver_query)
                    # insert into owns
                    add_owns_query = "CALL add_owns('{}', '{}');".format(current_user.username, plate_num)
                    db.session.execute(add_owns_query)
                    db.session.commit()
                    return render_template("car-registration.html", current_user=current_user, success=True)
        return render_template("car-registration.html", current_user=current_user)
    else:
        return redirect("/login")


@view.route("/create-advertisement", methods=["GET", "POST"])
def render_create_advertisement_page():
    if current_user.is_authenticated:
        car_list_query = "SELECT brand, plate_number FROM owns NATURAL JOIN car WHERE owns.driver_id = '{}';".format(
            current_user.username)
        car_list = db.session.execute(car_list_query).fetchall()
        if len(car_list) == 0:
            return redirect("/car-registration")
        place_list_query = "SELECT * FROM place;"
        place_list = db.session.execute(place_list_query).fetchall()
        print(car_list)
        if request.method == "POST":
            from_place = request.form['from']
            to_place = request.form['to']
            num_passenger = request.form['no_passengers']
            price = request.form['price']
            car_model = request.form['car_model']
            departure_time = request.form['departure_time']
            ad_status = "Active"
            if from_place == "" or to_place == "" or num_passenger == "" or car_model == "" or price == "":
                return render_template("create-advertisement.html", current_user=current_user,
                                       car_model_list=car_list,
                                       place_list=place_list, empty_error=True)
            elif(int(num_passenger) <= 0):
                return render_template("create-advertisement.html", current_user=current_user,
                                       car_model_list=car_list,
                                       place_list=place_list, negative_passenger_error=True)
            else:
                if from_place == to_place:
                    return render_template("create-advertisement.html", current_user=current_user,
                                           car_model_list=car_list,
                                           place_list=place_list, same_place_error=True)
                else:
                    # check number of passengers
                    split_string = car_model.split("|")
                    car_plate_number = split_string[1]

                    check_size_query = "SELECT no_passengers from car WHERE car.plate_number = '{}' ".format(
                        car_plate_number)
                    check_size = db.session.execute(check_size_query).fetchall()
                    print(check_size)
                    if int(num_passenger) > check_size[0][0]:
                        return render_template("create-advertisement.html", current_user=current_user,
                                               car_model_list=car_list,
                                               place_list=place_list, exceed_limit_error=True)
                    else:
                        add_advertisement_query = "INSERT INTO advertisement(time_posted, driver_id, num_passengers, departure_time, price, to_place, from_place, ad_status) " \
                                                  "VALUES (CURRENT_TIMESTAMP::timestamp(0), '{}', '{}', '{}', '{}', '{}', '{}', '{}')".format \
                            (current_user.username, num_passenger, departure_time, price, to_place, from_place,
                             ad_status)
                        db.session.execute(add_advertisement_query)
                        db.session.commit()
                        return render_template("create-advertisement.html", current_user=current_user,
                                               car_model_list=car_list,
                                               place_list=place_list, success=True)

        return render_template("create-advertisement.html", current_user=current_user, car_model_list=car_list,
                               place_list=place_list)
    else:
        return redirect("/login")


@view.route("/view-advertisement", methods=["GET"])
def render_view_advertisement_page():
    if current_user.is_authenticated:

        is_current_user_a_driver = Driver.query.filter_by(username=current_user.username).first()

        if is_current_user_a_driver:
            driver_ad_list_query = "SELECT a.time_posted::timestamp(0) as date_posted, a.departure_time::timestamp(0) as departure_time, a.from_place, a.to_place, " \
                                   "(SELECT max(price) from bids b where b.time_posted = a.time_posted and b.driver_id = '{0}') as highest_bid," \
                                   "(SELECT count(*) from bids b where b.time_posted = a.time_posted and b.driver_id = '{0}') as num_bidders," \
                                   "(a.departure_time::timestamp(0) - CURRENT_TIMESTAMP::timestamp(0) - '30 minutes'::interval) as time_remaining," \
                                   "a.ad_status as ad_status" \
                                   " from advertisement a where a.departure_time > (CURRENT_TIMESTAMP + '30 minutes'::interval) and a.driver_id = '{0}'".format(
                current_user.username)
            driver_ad_list = db.session.execute(driver_ad_list_query).fetchall()

            driver_bid_list_query = "select a.time_posted::timestamp(0) as date_posted, " \
                                    "b.passenger_id, b.price, a.num_passengers " \
                                    "from advertisement a JOIN bids b ON a.driver_id = b.driver_id and a.time_posted = b.time_posted " \
                                    "where " \
                                    "b.driver_id= '{}'".format(current_user.username)
            driver_bid_list = db.session.execute(driver_bid_list_query).fetchall()

            return render_template("view-advertisement.html", current_user=current_user, driver_ad_list=driver_ad_list,
                                   driver_bid_list=driver_bid_list)
        else:
            # disallow user to view advertisement that he has created if he's not a driver in the first place
            message = "Please register a car in order to view your list of advertisements!"
            return render_template("car-registration.html", message=message)
    else:
        return redirect("/login")


@view.route("/privileged-page", methods=["GET"])
@login_required
def render_privileged_page():
    return "<h1>Hello, {}!</h1>".format(current_user.first_name or current_user.username)


####
# BID RELATED FUNCTIONALITIES
####
@view.route("/delete_bid", methods=["GET", "POST"])
def delete_bid():
    print('request.form: ', request.form)
    query = "DELETE FROM Bids WHERE (passenger_ID, time_posted, driver_ID) = ('{}', '{}', '{}')" \
        .format(current_user.username, request.form['dateposted'], request.form['driver_id'])
    print(query)
    db.session.execute(query)
    db.session.commit()
    return redirect("/")


@view.route("/payment/<ride_id>", methods=["GET"])
def get_payment_page(ride_id):
    query = "SELECT r.ride_id, r.time_posted, r.driver_id, b.price" \
            " FROM Ride r INNER JOIN Bids b " \
            "ON r.driver_id = b.driver_id and r.time_posted = b.time_posted and r.passenger_id = b.passenger_id" \
            " WHERE r.ride_id = '{}' and r.passenger_id = '{}'".format(ride_id, current_user.username)

    payment_details = db.session.execute(query).fetchone()

    bid_price = payment_details[3]
    best_promo_query = "SELECT p.promo_code, p.discount FROM Promo p " \
                       "WHERE p.min_price <= {} " \
                       "and p.max_quota > (SELECT COUNT(*) FROM Redeems r WHERE r.promo_code = p.promo_code)" \
                       "GROUP BY p.promo_code, p.discount " \
                       "HAVING p.discount = max(p.discount)".format(bid_price)
    best_promo = db.session.execute(best_promo_query).fetchone()
    best_promo_message = ""
    if best_promo:
        best_promo_message = "Psst! Here's the best possible promo code (${} off) you could use: {}".format(
            best_promo[1], best_promo[0])
        print(best_promo_message)
    form = PaymentForm()

    return render_template("payment.html", details=payment_details, form=form, best_promo_message=best_promo_message)


@view.route("/payment/<ride_id>", methods=["POST"])
def pay(ride_id):
    query = "SELECT r.ride_id, r.time_posted, r.driver_id, b.price" \
            " FROM Ride r INNER JOIN Bids b " \
            "ON r.driver_id = b.driver_id and r.time_posted = b.time_posted and r.passenger_id = b.passenger_id" \
            " WHERE r.ride_id = '{}' and r.passenger_id = '{}'".format(ride_id, current_user.username)
    update_ride_payment_status_query = "UPDATE Ride SET is_paid = TRUE WHERE ride_id = '{}'".format(ride_id)

    payment_details = db.session.execute(query).fetchone()
    form = PaymentForm()

    if form.is_submitted:
        promo_code = form.promo_code.data
        promo_query = "SELECT * from promo WHERE promo_code = '{}'".format(promo_code)
        exists_promo = db.session.execute(promo_query).fetchone()
        current_bid_price = payment_details[3]
        form.promo_code.errors = []
        is_paid_ride_query = "SELECT * FROM Ride WHERE is_paid=TRUE"
        is_paid_ride = db.session.execute(is_paid_ride_query).fetchone()

        if is_paid_ride:
            form.message = "You already paid for the ride!"
        elif exists_promo:
            num_used_for_promo_query = "SELECT COUNT(*) FROM Redeems WHERE promo_code = '{}'".format(promo_code)
            num_used_for_promo = db.session.execute(num_used_for_promo_query).fetchone()[0]
            max_quota = exists_promo[1]
            min_price_to_use_promo = exists_promo[3]
            discount_amount = exists_promo[4]

            if num_used_for_promo >= max_quota:
                form.promo_code.errors.append("Promo code has been fully redeemed!")
            elif current_bid_price < min_price_to_use_promo:
                form.promo_code.errors.append("Your ride does not fulfill the minimum price of ${} "
                                              "to use this promo!".format(min_price_to_use_promo))
            else:
                redeems_insertion_query = "INSERT INTO redeems(ride_id, promo_code, username) " \
                                          "VALUES ('{}', '{}', '{}')".format(ride_id, promo_code, current_user.username)
                db.session.execute(redeems_insertion_query)
                db.session.execute(update_ride_payment_status_query)
                db.session.commit()

                discounted_price = current_bid_price - discount_amount

                # handle discount that exceeds the bid_price
                if discounted_price < 0:
                    discount_amount += discounted_price
                    discounted_price = 0

                form.message = "Payment of ${} (Discount of ${}) Successful!".format(discounted_price, discount_amount)

        elif not promo_code:  # user did not type promo code
            db.session.execute(update_ride_payment_status_query)
            db.session.commit()
            form.message = "Payment of ${} Successful!".format(current_bid_price)
        else:
            form.promo_code.errors.append('Promo code does not exists!')

    return render_template("payment.html", details=payment_details, form=form)


####
# SCHEDULE RELATED FUNCTIONAALITIES
####
@view.route("/update_pickup_status", methods=["POST"])
def update_pickup_status():
    query = "UPDATE Ride SET status = (CASE "\
        "WHEN status = 'pending' THEN 'ongoing' "\
        "ELSE 'completed' END) "\
        "WHERE ride_ID = {}".format(request.form['ride_id'])
    db.session.execute(query)
    db.session.commit()
    return '0'

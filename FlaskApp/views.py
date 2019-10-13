from flask import Blueprint, redirect, render_template
from flask_login import current_user, login_required, login_user

from __init__ import db, login_manager
from forms import LoginForm, RegistrationForm
from models import WebUser

view = Blueprint("view", __name__)


@login_manager.user_loader
def load_user(username):
    user = WebUser.query.filter_by(username=username).first()
    return user or current_user


@view.route("/", methods=["GET"])
def render_home_page():
    if current_user.is_authenticated:
        return render_template("home.html", current_user=current_user)
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
        query = "SELECT * FROM web_user WHERE username = '{}'".format(username)
        exists_user = db.session.execute(query).fetchone()
        if exists_user:
            form.username.errors.append("{} is already in use.".format(username))
        else:
            query = "INSERT INTO web_user(username, first_name, last_name, password) VALUES ('{}', '{}', '{}', '{}')"\
                .format(username, first_name, last_name, password)
            db.session.execute(query)
            db.session.commit()
            form.message = "Register successful! Please login with your newly created account."
    return render_template("registration.html", form=form)


@view.route("/login", methods=["GET", "POST"])
def render_login_page():
    form = LoginForm()
    if form.is_submitted():
        print("username entered:", form.username.data)
        print("password entered:", form.password.data)
        print(form.validate_on_submit())
    if form.validate_on_submit():
        user = WebUser.query.filter_by(username=form.username.data).first()
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
    if current_user.is_authenticated:
        return render_template("scheduled.html", current_user=current_user)
    else:
        return redirect("/login")

@view.route("/car-registration", methods=["GET"])
def render_car_registration_page():
    if current_user.is_authenticated:
        return render_template("car-registration.html", current_user=current_user)
    else:
        return redirect("/login")

@view.route("/create-advertisement", methods=["GET", "POST"])
def render_create_advertisement_page():
    if current_user.is_authenticated:
        return render_template("create-advertisement.html", current_user=current_user)
    else:
        return redirect("/login")

@view.route("/view-advertisement", methods=["GET"])
def render_view_advertisement_page():
    if current_user.is_authenticated:
        return render_template("view-advertisement.html", current_user=current_user)
    else:
        return redirect("/login")

@view.route("/privileged-page", methods=["GET"])
@login_required
def render_privileged_page():
    return "<h1>Hello, {}!</h1>".format(current_user.first_name or current_user.username)

from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SelectField, HiddenField, DecimalField
from wtforms.validators import InputRequired, ValidationError


def is_valid_name(form, field):
    if not all(map(lambda char: char.isalpha() or char.isnumeric(), field.data)):
        raise ValidationError('This field should only contain alphanumerics!')


def is_valid_number(form, field):
    if not all(map(lambda char: char.isnumeric(), field.data)):
        raise ValidationError('This field should only contain numerics!')

def is_valid_positiveNumber(form, field):
    if not all(map(lambda val: val.isnumeric() and float(val) > 0, field.data)):
        raise ValidationError('This field should be a non negative numeric value!')

def is_valid_integer(form, field):
    if not all(map(lambda val: val.isdigit(), field.data)):
        raise ValidationError('This field should be an integer!')


def agrees_terms_and_conditions(form, field):
    if not field.data:
        raise ValidationError('You must agree to the terms and conditions to sign up')


class RegistrationForm(FlaskForm):
    username = StringField(
        label='Username',
        validators=[InputRequired(), is_valid_name],
        render_kw={'placeholder': 'Username'}
    )
    first_name = StringField(
        label='First Name',
        validators=[InputRequired(), is_valid_name],
        render_kw={'placeholder': 'First Name'}
    )
    last_name = StringField(
        label='Last name',
        validators=[InputRequired(), is_valid_name],
        render_kw={'placeholder': 'Last Name'}
    )
    phone_number = StringField(
        label='Phone Number',
        validators=[InputRequired(), is_valid_number],
        render_kw={'placeholder': 'Phone Number'}
    )
    password = PasswordField(
        label='Password',
        validators=[InputRequired()],
        render_kw={'placeholder': 'Password'}
    )


class LoginForm(FlaskForm):
    username = StringField(
        label='Username',
        validators=[InputRequired()],
        render_kw={'placeholder': 'Username', 'class': 'input100'}
    )
    password = PasswordField(
        label='Password',
        validators=[InputRequired()],
        render_kw={'placeholder': 'Password', 'class': 'input100'}
    )


class BidForm(FlaskForm):
    hidden_did = HiddenField()
    hidden_timeposted = HiddenField()
    hidden_maxPax = HiddenField()
    price = StringField(
        label='Price',
        validators=[InputRequired(), is_valid_positiveNumber],
        render_kw={'placeholder': 'Bidding Price ($)'}
    )
    # choices=[(1, 1), (2, 2), (3, 3), (4, 4)]
    no_passengers = StringField(
        label='# of Passengers',
        validators=[InputRequired(), is_valid_positiveNumber, is_valid_integer],
        render_kw={'placeholder': 'no. of passengers'}
    )


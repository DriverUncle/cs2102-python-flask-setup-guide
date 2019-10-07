from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField
from wtforms.validators import InputRequired, ValidationError


def is_valid_name(form, field):
    if not all(map(lambda char: char.isalpha(), field.data)):
        raise ValidationError('This field should only contain alphabets')


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
        validators=[is_valid_name],
        render_kw={'placeholder': 'Last name'}
    )
    password = PasswordField(
        label='Password',
        validators=[InputRequired()],
        render_kw={'placeholder': 'Password'}
    )
    # car_plate = StringField(
    #     label='Car Plate Number',
    #     validators=[InputRequired()],
    #     render_kw={'placeholder': 'Car Plate Number'}
    # )
    # car_brand = PasswordField(
    #     label='Car Brand',
    #     validators=[InputRequired()],
    #     render_kw={'placeholder': 'Car Brand'}
    # )
    # car_model = PasswordField(
    #     label='Car Model',
    #     validators=[InputRequired()],
    #     render_kw={'placeholder': 'Car Model'}
    # )
    # car_colour = PasswordField(
    #     label='Car Colour',
    #     validators=[InputRequired()],
    #     render_kw={'placeholder': 'Car Colour'}
    # )
    # car_size = PasswordField(
    #     label='Car Size',
    #     validators=[InputRequired()],
    #     render_kw={'placeholder': 'Car Size'}
    # )


class LoginForm(FlaskForm):
    username = StringField(
        label='Name',
        validators=[InputRequired()],
        render_kw={'placeholder': 'Name', 'class': 'input100'}
    )
    password = PasswordField(
        label='Password',
        validators=[InputRequired()],
        render_kw={'placeholder': 'Password', 'class': 'input100'}
    )

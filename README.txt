=========================
Pre-requisites
=========================
Ensure that you have the following installed:

1. PostgreSQL
2. Python 3.5 (and above)
3. Google Chrome (other browsers may not be supported)


=========================
Setup Guide
=========================
1. Clone the files from its github repo at https://github.com/DriverUncle/TumpangMePlease.git . 
	Clone the repo to your desired directory.
2. Open a terminal, set the directory to the cloned repo, then run the following command to install the dependencies:
	a. for pip: pip install -r requirements.txt
	b. for conda: conda install --file requirements.txt
3. In the terminal, launch PostgreSQL, and load the data from /init.sql into the database.
4. In the file FlaskApp/app.py, ensure that the login details match the existing ones in your PostgreSQL.

				# Config
				app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://{username}:{password}@{host}:{port}/{database}'\
					.format(
						username='postgres', # Your PostgreSQL username here
						password='password', # Your Password here
						host='localhost',
						port=5432,
						database='postgres'
					)
				app.config['SECRET_KEY'] = 'A random key to use CRF for forms'
				
	Note: Replace <username>, <password>, <port>, and <database_name> with the actual configuration from your database.
	If you are not sure about <port> and don't recall changing such a value during initial setup or launching of
	PostgreSQL server, then it should be 5432 by default.			
5. In the terminal, set the directory to the cloned repo, then run the following command to start the
	development server: python FlaskApp/app.py
6. In chrome, type the following address http://localhost:5000/ to launch the app.


=========================
Note
=========================
The full README can be found at https://github.com/DriverUncle/TumpangMePlease#tumpang-me-please 
This README only provides the tutorial for setting up the app.

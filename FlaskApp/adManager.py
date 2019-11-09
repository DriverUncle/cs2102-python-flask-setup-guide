"""
PS: idk how to name this page
"""

from flask_login import current_user
from __init__ import db

import datetime


# Returns the list of ads according to list of keywords. 
def get_filtered_ads(keywords, username):
    ad_list_query = "SELECT a.time_posted::timestamp(0) as date_posted, a.departure_time::timestamp(0) as departure_time, " \
                    "a.driver_id, (SELECT d_rating FROM Driver WHERE username = a.driver_id), a.from_place, a.to_place, a.num_passengers, a.price, " \
                    "(SELECT max(price) from bids b where b.time_posted = a.time_posted and b.driver_id = a.driver_id) as highest_bid," \
                    "(SELECT count(*) from bids b where b.time_posted = a.time_posted and b.driver_id = a.driver_id) as num_bidders," \
                    "(a.departure_time::timestamp(0) - CURRENT_TIMESTAMP::timestamp(0) - '30 minutes'::interval) as time_remaining" \
                    " from advertisement a where a.departure_time > (CURRENT_TIMESTAMP + '30 minutes'::interval) and ad_status = 'Active' and a.driver_id <> '{}'".format(username)
    
    # Append search term if keywords isn't empty
    if (len(keywords) != 0):
        ad_list_query += "AND ("
        for i in range(len(keywords)):
            ad_list_query += "LOWER(to_place) LIKE LOWER('%{}%')".format(keywords[i])
            if (i+1) < len(keywords):
                ad_list_query += " OR "
        ad_list_query += ");"

    return db.session.execute(ad_list_query).fetchall()


# Returns true if dateTime is 1 hr after current time.
def is_oneHourAfterCurrTime(test):
    date_time_obj = datetime.datetime.strptime(test, '%m/%d/%Y %I:%M %p')
    return True if date_time_obj > (datetime.datetime.now() + datetime.timedelta(hours=1)) else False

# Returns the time in strict-ISO format.
def get_dateTime_strictISO(dateTime):
    date_time_obj = datetime.datetime.strptime(dateTime, '%m/%d/%Y %I:%M %p')
    return date_time_obj.isoformat()

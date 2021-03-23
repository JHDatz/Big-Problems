# Fangraph Scrape
#
# Written by: Joe Datz
# Date: 3/23/21
#
# This python script was made to get birthdays directly off of Fangraphs.com
# For our project. We would like to produce aging curves for our project, but
# in the dataset fgTotal.csv we do not currently have birthdays with which to
# make ages. This web scraper is meant to alleviate this.

from bs4 import BeautifulSoup
import requests
import pandas as pd
import mysql.connector

# This helper function will allow us to use a list comprehension. It takes a
# fangraphs player ID as input to the function. With it, it connects to the
# internal API service for Fangraphs to go to a particular player's webpage.
# from that webpage we pull the DOB of the player and return a short list
# of the player's ID and their DOB if found.

def helper_function(playerid):
    get_page = requests.get('https://www.fangraphs.com/statss.aspx?playerid=' + str(playerid))
    soup = BeautifulSoup(get_page.text, 'html.parser')

    try:
        dob = soup.find('tr', {'class': 'player-info__bio-birthdate'}).text.split(" ")[1]
    except AttributeError:
        dob = None

    return [playerid, dob]

# First, connect to the MySQL server.

user = 'r-user',
password = 'h2p@4031'
host = 'saberbase.cn2snhhvsjfa.us-east-2.rds.amazonaws.com',
database = 'imaginaryLeague'

conn = mysql.connector.connect(user = user, password = password, host = host, port = 3306, database = database)

# We already have the playerIDs we'd like to find birthdays for in the table
# fgtotal, so we get pull these from the server.

cur = conn.cursor()
data = pd.read_sql("select playerid from fgTotal", conn)
data['playerid'] = data['playerid'].astype('int64')
#print(list(data['playerid']))
conn.close()

# Using the helper function, we create a list using list comprehensions.

dob_data = [helper_function(playerid) for playerid in list(data['playerid'])]

# Convert to a pandas dataframe to take advantage of pandas' SQL tools.

dob_data = pd.DataFrame(dob_data, columns=['playerid', 'dob'])

# Reconnect to the MySQL server and upload the data.

conn = mysql.connector.connect(user = user, password = password, host = host, port = 3306, database = database)

dob_data.to_sql('fgDOB', conn)
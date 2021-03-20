# If running in Jupyter Notebook, you'll need to make changes in Jupyter's config file by using the following link:
# https://stackoverflow.com/questions/43288550/iopub-data-rate-exceeded-in-jupyter-notebook-when-viewing-image

import mysql.connector

conn = mysql.connector.connect(user = 'redacted', password = 'redacted',
                               host = 'redacted',
                               port = 3306,
                               database = 'lahman')

cur = conn.cursor()
cur.execute("blah blah blah")
print(cur.fetchall())

conn.close()
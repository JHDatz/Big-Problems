import mysql.connector

conn = mysql.connector.connect(user = 'redacted', password = 'redacted',
                               host = 'redacted',
                               port = 3306,
                               database = 'lahman')

cur = conn.cursor()
cur.execute("blah blah blah")
print(cur.fetchall())

conn.close()
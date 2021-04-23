# QCQP Convex Optimization
#
# Written By: Joe Datz
# Date: 3/23/21
#
# This standard python file contains a method for finding the best positions
# of fielders using convex optimization. We have formulated this optimization
# to be a class of QCQP problems and the problem statement can be found in an
# accompanying PDF of a LaTeX file.
#
# This is an improvement on the Convex Test jupyter notebook file. This now
# accepts more realistic constraints. But in doing so, this is now an NP hard
# problem and the minimum found is no longer guaranteed to be the global
# minimum. I also found the optimizer to be a bit finnicky and need to be
# restarted to avoid numerical overflow.
#
# Important future considerations:
#
# 1. I still maintain that something needs to be added to the objective function
# or the constraints to account for run value. As it stands now we treat high
# run-value and low run-value batted balls with equal importance.
#
# 2. Other methods of problem solving, such as evolutionary programming, are also
# likely viable with enough legwork.
#
# 3. I had to use Python 3.6 as well as CVXpy 0.4.9 and scipy 0.1.1 to make this
# work. QCQP has not been updated to keep up with more recent editions of CVXpy.
# Downgrading to CVXpy 0.4.9 is also why this is no longer vectorized; Numpy
# seem to be finicky here.
#
# This file was originally created in Jupyter Notebook but transferred to a
# standard .py file on 4/16/21 for documentation purposes; some people who would
# be interested in reading the file might prefer a .py to a .ipynb format.

import cvxpy as cp
import numpy as np
import mysql.connector
import pandas as pd
from qcqp import *
from itertools import combinations

# Fit a curve constraint

def curve_fit(coordinates1, coordinates2, coordinates3):
    y = np.array([coordinates1[1], coordinates2[1], coordinates3[1]])
    x = np.array([[coordinates1[0]**2, coordinates1[0], 1],
                  [coordinates2[0]**2, coordinates2[0], 1],
                  [coordinates3[0]**2, coordinates3[0], 1]])
    constants = np.linalg.inv(x.T.dot(x)).dot(x.T).dot(y)
    return constants[0], constants[1], constants[2]

[a1, b1, c1] = curve_fit((84.85, 84.85), (0, 157.28), (-84.85, 84.85)) # shallow outfield
[a2, b2, c2] = curve_fit((-229.809, 229.809), (0, 400), (229.809, 229.809)) # outfield max

conn = mysql.connector.connect(user = 'redacted', password = 'redacted',
                               host = 'redacted',
                               port = 3306,
                               database = 'redacted')
cur = conn.cursor()
cur.execute("select ballpos_x, ballpos_y from rawFiltered where batterid = 605137") # Josh Bell
data = np.array(cur.fetchall())
conn.close()

# Define the X-Y coordinates of players to optimize as variables.

firstBaseX = cp.Variable()
firstBaseY = cp.Variable()
secondBaseX = cp.Variable()
secondBaseY = cp.Variable()
thirdBaseX = cp.Variable()
thirdBaseY = cp.Variable()
shortstopX = cp.Variable()
shortstopY = cp.Variable()
leftFieldX = cp.Variable()
leftFieldY = cp.Variable()
centerFieldX = cp.Variable()
centerFieldY = cp.Variable()
rightFieldX = cp.Variable()
rightFieldY = cp.Variable()

# Define the objective function as minimizing the distance between a particular batter's
# batted ball X-Y coordinates and a fielder's x-y coordinates

objective = 0
for j in range(len(data)):
    objective = objective + cp.square(data[j,0] - firstBaseX) + cp.square(data[j,1] - firstBaseY) + \
                            cp.square(data[j,0] - secondBaseX) + cp.square(data[j,1] - secondBaseY) + \
                            cp.square(data[j,0] - thirdBaseX) + cp.square(data[j,1] - thirdBaseY) + \
                            cp.square(data[j,0] - shortstopX) + cp.square(data[j,1] - shortstopY) + \
                            cp.square(data[j,0] - leftFieldX) + cp.square(data[j,1] - leftFieldY) + \
                            cp.square(data[j,0] - centerFieldX) + cp.square(data[j,1] - centerFieldY) + \
                            cp.square(data[j,0] - rightFieldX) + cp.square(data[j,1] - rightFieldY)


constraints = [firstBaseY >= 63.64,
               secondBaseY >= 63.64,
               thirdBaseY >= 63.64,
               shortstopY >= 63.64,
               leftFieldY >= 63.64,
               centerFieldY >= 63.64,
               rightFieldY >= 63.64, # No one in front of pitcher
               firstBaseX <= firstBaseY,
               secondBaseX <= secondBaseY,
               thirdBaseX <= thirdBaseY,
               shortstopX <= shortstopY,
               leftFieldX <= leftFieldY,
               centerFieldX <= centerFieldY,
               rightFieldX <= rightFieldY,
               -firstBaseX <= firstBaseY,
               -secondBaseX <= secondBaseY,
               -thirdBaseX <= thirdBaseY,
               -shortstopX <= shortstopY,
               -leftFieldX <= leftFieldY,
               -centerFieldX <= centerFieldY,
               -rightFieldX <= rightFieldY, # No one past foul lines
               a1*cp.square(firstBaseX) + b1*firstBaseX + c1 >= firstBaseY,
               a1*cp.square(secondBaseX) + b1*secondBaseX + c1 >= secondBaseY,
               a1*cp.square(thirdBaseX) + b1*thirdBaseX + c1 >= thirdBaseY,
               a1*cp.square(shortstopX) + b1*shortstopX + c1 >= shortstopY, # IFers don't go past shallow OF
               a1*cp.square(leftFieldX) + b1*leftFieldX + c1 <= leftFieldY,
               a1*cp.square(centerFieldX) + b1*centerFieldX + c1 <= centerFieldY,
               a1*cp.square(rightFieldX) + b1*rightFieldX + c1 <= rightFieldY, # OFers stay in outfield
               a2*cp.square(leftFieldX) + b2*leftFieldX + c2 >= leftFieldY,
               a2*cp.square(centerFieldX) + b2*centerFieldX + c2 >= centerFieldY,
               a2*cp.square(rightFieldX) + b2*rightFieldX + c2 >= rightFieldY, # OFers stay inside field
               cp.square(firstBaseX - 63.64) + cp.square(firstBaseY - 63.74) <= 30**2, # 1B 30ft from 1st
               cp.square(firstBaseX - secondBaseX) + cp.square(firstBaseY - secondBaseY) >= 15**2,
               cp.square(firstBaseX - thirdBaseX) + cp.square(firstBaseY - thirdBaseY) >= 15**2,
               cp.square(firstBaseX - shortstopX) + cp.square(firstBaseY - shortstopY) >= 15**2,
               cp.square(firstBaseX - leftFieldX) + cp.square(firstBaseY - leftFieldY) >= 30**2,
               cp.square(firstBaseX - centerFieldX) + cp.square(firstBaseY - centerFieldY) >= 30**2,
               cp.square(firstBaseX - rightFieldX) + cp.square(firstBaseY - rightFieldY) >= 30**2,
               cp.square(secondBaseX - thirdBaseX) + cp.square(secondBaseY - thirdBaseY) >= 15**2,
               cp.square(secondBaseX - shortstopX) + cp.square(secondBaseY - shortstopY) >= 15**2,
               cp.square(secondBaseX - leftFieldX) + cp.square(secondBaseY - leftFieldY) >= 30**2,
               cp.square(secondBaseX - centerFieldX) + cp.square(secondBaseY - centerFieldY) >= 30**2,
               cp.square(secondBaseX - rightFieldX) + cp.square(secondBaseY - rightFieldY) >= 30**2,
               cp.square(thirdBaseX - shortstopX) + cp.square(thirdBaseY - shortstopY) >= 15**2,
               cp.square(thirdBaseX - leftFieldX) + cp.square(thirdBaseY - leftFieldY) >= 30**2,
               cp.square(thirdBaseX - centerFieldX) + cp.square(thirdBaseY - centerFieldY) >= 30**2,
               cp.square(thirdBaseX - rightFieldX) + cp.square(thirdBaseY - rightFieldY) >= 30**2,
               cp.square(shortstopX - leftFieldX) + cp.square(shortstopY - leftFieldY) >= 30**2,
               cp.square(shortstopX - centerFieldX) + cp.square(shortstopY - centerFieldY) >= 30**2,
               cp.square(shortstopX - rightFieldX) + cp.square(shortstopY - rightFieldY) >= 30**2,
               cp.square(leftFieldX - centerFieldX) + cp.square(leftFieldY - centerFieldY) >= 30**2,
               cp.square(leftFieldX - rightFieldX) + cp.square(leftFieldY - rightFieldY) >= 30**2,
               cp.square(centerFieldX - rightFieldX) + cp.square(centerFieldY - rightFieldY) >= 30**2]
               # Players stay a certain radius away from each other. For OFers it's 30 feet, for IFers
               # it's 15 feet. Ideally we'd update this to reflect individual skill level.

prob = cp.Problem(cp.Minimize(objective), constraints)
qcqp = QCQP(prob)

print('Optimal Value:', qcqp.improve(ADMM)) # Run the ADMM optimizer algorithm and find a local minimum.
print('Optimal 1B Position', firstBaseX.value, firstBaseY.value)
print('Optimal 2B Position', secondBaseX.value, secondBaseY.value)
print('Optimal 3B Position', thirdBaseX.value, thirdBaseY.value)
print('Optimal Shortstop Position', shortstopX.value, shortstopY.value)
print('Optimal Left Fielder Position', leftFieldX.value, leftFieldY.value)
print('Optimal Center Fielder Position', centerFieldX.value, centerFieldY.value)
print('Optimal Right Fielder Position', rightFieldX.value, rightFieldY.value)
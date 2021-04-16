# Convex Optimization Test
#
# Written By: Joe Datz
# Date: 3/22/21
#
# This standard python file contains a method for finding the best positions
# of fielders using convex optimization. We have formulated this optimization
# to be a class of QCQP problems and the problem statement can be found in an
# accompanying PDF of a LaTeX file.
#
# Important future considerations:
#
# 1. The problem is QCQP but we are using QP software, which greatly limits our
# modeling abilities. This will need to be changed to more properly define
# constraints.
#
# 2. I still maintain that something needs to be added to the objective function
# or the constraints to account for run value. As it stands now we treat high
# run-value and low run-value batted balls with equal importance.
#
# 3. Other methods of problem solving, such as evolutionary programming, are also
# likely viable with enough legwork.
#
# This file was originally created in Jupyter Notebook but transferred to a
# standard .py file on 4/16/21 for documentation purposes; some people who would
# be interested in reading the file might prefer a .py to a .ipynb format.

import cvxpy as cp
import numpy as np
import mysql.connector
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
                               database = 'figmentLeague')
cur = conn.cursor()
cur.execute("select ballpos_x, ballpos_y from rawFiltered where batterid = 605137") # Josh Bell
data = np.array(cur.fetchall())
conn.close()

# Define the X-Y coordinates of players to optimize as variables.

positions = cp.Variable((7, 2))

# Define the objective function as minimizing the distance between a particular batter's
# batted ball X-Y coordinates and

objective = [cp.norm(cp.vec(data[:,0] - positions[i,0])) + cp.norm(cp.vec(data[:,1] - positions[i,1]))
             for i in range(positions.shape[0])]

constraints = [positions[:,1] >= 63.64, # Everyone behind pitcher's mound
               positions[:,0] <= positions[:,1], # No one past right foul line
               -positions[:,0]<= positions[:,1], # No one past left foul line
               a1*cp.square(positions[0:4,0]) + b1*positions[0:4,0] + c1*np.ones((4,1))[0:5,0] >= positions[0:4,1],
               a2*cp.square(positions[:,0]) + b2*positions[:,0] + c2*np.ones((7,1))[:,0] >= positions[:,1],
               cp.square(positions[0,0] - 63.64) + cp.square(positions[0,1] - 63.74) <= 30**2, # 1B 30ft from 1st
              ]

prob = cp.Problem(cp.Minimize(cp.sum(objective)), constraints)

print('optimal value:', prob.solve())
print('Optimal 1B Position', positions[0,:].value)
print('Optimal 2B Position', positions[1,:].value)
print('Optimal 3B Position', positions[2,:].value)
print('Optimal Shortstop Position', positions[3,:].value)
print('Optimal Left Fielder Position', positions[4,:].value)
print('Optimal Center Fielder Position', positions[5,:].value)
print('Optimal Right Fielder Position', positions[6,:].value)

# Constraints to be added by appending QCQP capabilities:

cp.norm(cp.vec(positions[0,:] - positions[1,:])) >= 30**2 # Keeping players squared distances away from each other

a1*cp.square(positions[4:7,0]) + b1*positions[4:7,0] + c1*np.ones((3,1))[0:4,0] <= positions[4:7,1] # Keep OF in OF

# Objective function penalties to be added by appending QCQP capabilities:

objective = objective + [cp.log(cp.abs(positions[i,0] - positions[j,0]))
                         for i,j in combinations([0,1,2,3,4,5,6], 2)]
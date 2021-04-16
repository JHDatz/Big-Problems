from scipy.optimize import minimize, NonlinearConstraint
from itertools import combinations
import numpy as np
import pandas as pd
import mysql.connector
from nonlinear_optimization_functions import *

[a1, b1, c1] = curve_fit((84.85, 84.85), (0, 157.28), (-84.85, 84.85)) # shallow outfield
[a2, b2, c2] = curve_fit((-229.809, 229.809), (0, 400), (229.809, 229.809)) # outfield max

conn = mysql.connector.connect(user = 'redacted', password = 'redacted',
                               host = 'redacted',
                               port = 3306,
                               database = 'figmentLeague')

cur = conn.cursor()
cur.execute("select ballpos_x, ballpos_y from rawFiltered where batterid = 518934") # D.J Lamehieu
data = pd.DataFrame(np.array(cur.fetchall()))
data['zones'] = data.apply(assign_buckets, args = (7,4), axis=1)
distribution = batted_ball_distribution(data)
conn.close()

# Placement of starting points along zones

x0, new_positions, zone_markers = assign_positions(distribution)

variable_locations = {'firstBaseStart': (0, 1), 'secondBaseStart': (2, 3), 'thirdBaseStart': (4, 5),
                      'shortstopStart': (6, 7), 'leftFieldStart': (8, 9),
                      'centerFieldStart': (10, 11), 'rightFieldStart': (12, 13)}


def new_objective(x):
    objective = 0

    for k in range(data.shape[0]):

        try:

            i, j = variable_locations[zone_markers[data['zones'][k]]]
            objective = (data[0][k] - x[i]) ** 2 + (data[1][k] - x[j]) ** 2

        except KeyError:

            pass

    #     for i,j in list(combinations([0, 2, 4, 6, 8, 10, 12], 2)):

    #         if j in [8,10,12]:

    #             objective = objective - 1e5*np.log(((x[i]-x[j])**2 + (x[i+1] - x[j+1])**2)/(60**2))

    #         else:

    #             objective = objective - 1e5*np.log(((x[i]-x[j])**2 + (x[i+1] - x[j+1])**2)/(20**2))

    #     for i,j in list(combinations([0, 2, 4, 6, 8, 10, 12], 2)):

    #         objective = objective - \
    #         1e3*np.log(np.arccos(((x[i]*x[j] + x[i+1]*x[j+1])/((x[i]**2 + x[i+1]**2)*(x[j]**2 + \
    #                                                                               x[j+1]**2))))*(180/np.pi)/4)

    return objective


bounds = [(-np.inf, np.inf), (0, np.inf), (-np.inf, np.inf), (0, np.inf), (-np.inf, np.inf), (0, np.inf),
          (-np.inf, np.inf), (0, np.inf), (-np.inf, np.inf), (0, np.inf), (-np.inf, np.inf), (0, np.inf),
          (-np.inf, np.inf), (0, np.inf)]

test = minimize(new_objective, x0, method = 'trust-constr', bounds = bounds)

test.x
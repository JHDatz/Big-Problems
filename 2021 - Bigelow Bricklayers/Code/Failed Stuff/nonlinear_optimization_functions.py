import numpy as np
import pandas as pd

def curve_fit(coordinates1, coordinates2, coordinates3):
    y = np.array([coordinates1[1], coordinates2[1], coordinates3[1]])
    x = np.array([[coordinates1[0] ** 2, coordinates1[0], 1],
                  [coordinates2[0] ** 2, coordinates2[0], 1],
                  [coordinates3[0] ** 2, coordinates3[0], 1]])
    constants = np.linalg.inv(x.T.dot(x)).dot(x.T).dot(y)
    return constants[0], constants[1], constants[2]


def rotation(i, splitSize):
    return (np.sin(i * np.deg2rad(90 / splitSize)) + \
            np.cos(i * np.deg2rad(90 / splitSize))) / (np.cos(i * np.deg2rad(90 / splitSize)) - \
                                                       np.sin(i * np.deg2rad(90 / splitSize)))


def partition(splitSize): return [rotation(i + 1, splitSize) for i in range(splitSize - 1)]


def starting_points(partition, infOf):
    coordinate_pairs = []

    if infOf == "Infield":
        radius = 165
    else:
        radius = 320

    for i in range(len(partition)):

        if i == 0:

            slope = (partition[0] + 1) / 2
            x = np.sqrt((radius ** 2) / (slope ** 2 + 1))
            y = np.sqrt(radius ** 2 - x ** 2)
            coordinate_pairs.append([x, y])

        elif i < len(partition):

            slope = (partition[i] + partition[i - 1]) / 2

            if partition[i] < 0:
                x = -np.sqrt((radius ** 2) / (slope ** 2 + 1))
            else:
                x = np.sqrt((radius ** 2) / (slope ** 2 + 1))

            y = np.sqrt(radius ** 2 - x ** 2)
            coordinate_pairs.append([x, y])

    slope = (partition[len(partition) - 1] - 1) / 2
    x = -np.sqrt((radius ** 2) / (slope ** 2 + 1))
    y = np.sqrt(radius ** 2 - x ** 2)
    coordinate_pairs.append([x, y])

    return coordinate_pairs


def zone_assignment(x, partition):
    for i in range(len(partition)):

        if partition[i] > 0 and partition[i] * x[0] > x[1]:
            return "Zone " + str(i + 1)

        elif partition[i] < 0 and partition[i] * x[0] < x[1]:
            return "Zone " + str(i + 1)

    return "Zone " + str(len(partition) + 1)


def infield_outfield(x):
    if x[1] ** 2 < 175 ** 2 - x[0] ** 2:
        return "Infield"
    else:
        return "Outfield"


def assign_buckets(x, infieldPartition, outfieldPartition):
    if infield_outfield(x) == "Infield":
        return "Infield " + zone_assignment(x, partition(infieldPartition))
    else:
        return "Outfield " + zone_assignment(x, partition(outfieldPartition))


def batted_ball_distribution(data):
    proportion = data.groupby('zones').count()
    proportion = proportion.drop(1, axis=1)
    proportion = proportion.rename(columns={0: 'prop'})
    proportion.index.name = 'zones'
    proportion.reset_index(inplace=True)
    proportion['prop'] = proportion['prop'] / sum(proportion['prop'])
    return proportion


def distance_calc(z, w): return np.sqrt((z[0] - w[0]) ** 2 + (z[1] - w[1]) ** 2)


def coord_assignment(initial, distribution, partitionSize, infOf):

    new_positions = {}
    zone_markers = {}

    while (len(initial) != 0):
        index = distribution[distribution.prop == max(distribution.prop)].index[0]
        field_segment = distribution[distribution.prop == max(distribution.prop)]['zones'][index]
        max_coordinate = starting_points(partition(partitionSize), infOf)[index]
        distribution = distribution.drop(index)

        distances = {key: distance_calc(max_coordinate, initial[key])
                     for key in initial.keys()}

        min_pair = min(distances.items(), key=lambda x: x[1])
        new_positions[min_pair[0]] = max_coordinate
        zone_markers[field_segment] = min_pair[0]
        initial.pop(min_pair[0])

    return new_positions, zone_markers


def assign_positions(distribution):

    initial_inf_positions = {'secondBaseStart': [0, 127.28],
                             'thirdBaseStart': [-63.64, 63.64], 'shortstopStart': [-31.28, 95.46]}

    initial_of_positions = {'leftFieldStart': [-134.67, 266.16], 'centerFieldStart': [0, 321.78],
                            'rightFieldStart': [134.67, 266.67]}

    infieldDist = distribution[distribution['zones'].apply(lambda x: 'Infield' in x)]
    outfieldDist = distribution[distribution['zones'].apply(lambda x: 'Outfield' in x)].reset_index()

    new_positions, zone_markers = coord_assignment(initial_inf_positions, infieldDist, 7, "Infield")
    new_of_positions, of_zone_markers = coord_assignment(initial_of_positions, outfieldDist, 5, "Outfield")

    new_positions.update(new_of_positions)
    zone_markers.update(of_zone_markers)

    zone_markers["Infield Zone 1"] = 'firstBaseStart'

    x0 = [[63.64, 63.64], new_positions['secondBaseStart'], new_positions['thirdBaseStart'],
          new_positions['shortstopStart'], new_positions['leftFieldStart'], new_positions['centerFieldStart'],
          new_positions['rightFieldStart']]

    x0 = [singleCoords for coords in x0 for singleCoords in coords]

    return x0, new_positions, zone_markers

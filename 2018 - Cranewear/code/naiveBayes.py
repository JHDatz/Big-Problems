import numpy as np
import csv
from sklearn.naive_bayes import BernoulliNB
from pathlib import Path
from collections import defaultdict
import random

mypath = 'C:/Users/Brian/Documents/BIG/Data_Final.csv'


# quick functions to access column vectors of the 2D dataset


def numcolumn(matrix, i):
    return [int(row[i]) for row in matrix]


def column(matrix, i):
    return [row[i] for row in matrix]


# splits the set of patient vectors into a training group and a test group.
# can change the ratio of train/test by adjusting the splitRatio parameter


def splitDataset(dataset, targets, splitRatio):
    trainSize = int(len(dataset) * splitRatio)
    trainSet = []
    trainTargets = []
    copy = list(dataset)
    testTargets = list(targets)

    while len(trainSet) < trainSize:
        index = random.randrange(len(copy))
        trainSet.append(copy.pop(index))
        trainTargets.append(testTargets.pop(index))
    return [trainSet, trainTargets, copy, testTargets]


# simple function to determine the accuracy of the classifier. Returns a
# percentage calculated from (correct predictions)/(total entries in test set).
# Also calculates "true accuracy", which is the number of correctly predicted
# readmitted patients over the total number of readmitted patients in test set.


def getAccuracy(actual, predicted):
    correct = 0
    truevals = 0
    truecorrect = 0
    falsepos = 0
    for x in range(len(actual)):
        if actual[x] == 1:
            truevals += 1
        if predicted[x] == 1 and actual[x] == 0:
            falsepos += 1
        if actual[x] == predicted[x]:
            correct += 1
            if actual[x] == 1:
                truecorrect += 1

    accuracy = correct/len(actual) * 100
    if truevals != 0:
        trueacc = truecorrect/truevals * 100
    else:
        trueacc = 'No true values in test set'
    return [accuracy, trueacc, truevals, truecorrect, falsepos]


# loading dataset into array from csv


vlen = 0
with open(mypath, newline='') as csvfile:
    Dreader = csv.reader(csvfile)
    v = []

    for row in Dreader:
        v.append(row)
        vlen = len(row)


# full dataset is in nested list 'v'. Then the non-binary rows and columns like
# the title row and the row of patients are removed. Then the binary row of
# readmitted patients is removed and stored as its own vector. The final working
# dataset is stored in the variable 'data'.


keys = v[0]
data = v[1:]
readmitted = column(data, 1)
k = 0
for val in readmitted:
    readmitted[k] = int(readmitted[k])
    k += 1
patnums = column(data, 0)
i = 0
for row in data:
    data[i] = data[i][2:]
    for j in range(vlen-2):
        data[i][j] = int(data[i][j])
    i += 1

print("load completed.")


# dataset is split with the given adjustable ratio.


splitRatio = 0.65
[train, trainTargets, test, testTargets] = splitDataset(data, readmitted, splitRatio)
print("split completed.")


# Training dataset is passed through the classifier, which is then used to
# predict the test dataset. Used the Bernoulli Naive Bayes classifier from the
# library 'sklearn'. The BernoulliNB is specifically used for large binary
# datasets.


clf = BernoulliNB(alpha=0.8)
clf.fit(train, trainTargets)
run = clf.predict(test)


# Accuracy and True Accuracy results are calculated and printed.


[acc, trueacc, truevals, truecorrect, falsepos] = getAccuracy(testTargets, run)
print('Accuracy = ', acc)
print('True Accuracy = ', trueacc, '.  Predicted ', truecorrect, ' out of ', truevals, ' readmitted in test set')
print("Predicted ", falsepos, " total false positives.")
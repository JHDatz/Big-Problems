from os import listdir
from os.path import isfile, join
import os
import csv

mypath = os.getcwd() + "/venv/MIMIC/"
listOfTotalLists = []
for a in listdir(mypath):

    if (os.path.isdir(mypath + a)):
        for f in listdir(mypath + a):

            if (os.path.isdir(mypath + a)):

                if (os.path.isdir(mypath + a +"/"+ f)):
                    totalLine = []
                    totalLine.append(f)
                    readmittance = False
                    print("f is " + f)
                    for d in listdir(mypath + a + "/" + f):

                        file = open(mypath + a + "/" + f + "/" + d)

                        if (d == "ADMISSIONS-" + f + ".txt"):
                            print("equal")
                            for i, line in enumerate(file):
                                print(i)
                                if i == 1:
                                    newStuff = line.split(",")
                                    newStuff[-1] = newStuff[-1].replace('\n', '')
                                    totalLine = totalLine + newStuff

                                if i == 2:
                                    readmittance = True
                                    print("What I want")

                            file.close()
                        if (d == "COMORBIDITY_SCORES-" + f + ".txt"):
                            print("equal")
                            for i, line in enumerate(file):
                                print(i)
                                if i == 1:
                                    newStuff = line.split(",")
                                    newStuff[-1] = newStuff[-1].replace('\n', '')
                                    totalLine = totalLine + newStuff

                            file.close()
                        if (d == "D_PATIENTS-" + f + ".txt"):
                            print("equal")
                            for i, line in enumerate(file):
                                print(i)
                                if i == 1:
                                    newStuff = line.split(",")
                                    newStuff[-1] = newStuff[-1].replace('\n', '')
                                    totalLine = totalLine + newStuff

                            file.close()
                        if (d == "DEMOGRAPHIC_DETAIL-" + f + ".txt"):
                            print("equal")
                            for i, line in enumerate(file):
                                print(i)
                                if i == 1:
                                    newStuff = line.split(",")
                                    print(newStuff[-1])
                                    print(newStuff[-1].replace('\n', ''))
                                    newStuff[-1] = newStuff[-1].replace('\n', '')
                                    totalLine = totalLine + newStuff

                            file.close()

                    if (readmittance == True):
                        totalLine = totalLine.append("1")

                    else:
                        totalLine.append("0")
                        # print("    "+ file.read())
                    if (totalLine != None):
                        listOfTotalLists.append(totalLine)


with open('DataSet.csv', "w") as output:
    writer = csv.writer(output, lineterminator='\n')
    writer.writerows(listOfTotalLists)





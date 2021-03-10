from os import listdir
from os.path import isfile, join
import os
import csv

def read():
    mypath = os.getcwd() + "/MIMIC/"
    #a directories
    patient_info = [[]]
    for a in listdir(mypath):
        if (os.path.isdir(mypath + a)):
            # f is the patient number
            for f in listdir(mypath + a):

                if (os.path.isdir(mypath + a)):

                    if (os.path.isdir(mypath + a +"/"+ f)):
                        totalLine = []
                        totalLine.append(f)
                        readmittance = False
                        # d is the file name
                        for d in listdir(mypath + a + "/" + f):

                            file_name = mypath + a + "/" + f + "/" + d

                            # these are the files we are currently looking at

                            '''
                            if (d == "*file*-" + f + ".txt"):
                               with open(file_name, 'r') as the_file:
                                   lines = the_file.readlines()
                                   lines = [x.strip() for x in lines]
                                   if len(lines)==0:
                                       break
                                   catagories = lines[0]
                                   for x in range (1, len(lines)):
                                       lines[x]=lines[x].split(',')
                            '''
                            #use the above string as a template to examine more files

                            if (d == "ADMISSIONS-" + f + ".txt"):
                               with open(file_name, 'r') as the_file:
                                   lines = the_file.readlines()
                                   lines = [x.strip() for x in lines]
                                   if len(lines)==0:
                                       break
                                   catagories = lines[0]
                                   for x in range (1, len(lines)):
                                       lines[x]=lines[x].split(',')

                            if (d == "COMORBIDITY_SCORES-" + f + ".txt"):
                                with open(file_name, 'r') as the_file:
                                    lines = the_file.readlines()
                                    lines = [x.strip() for x in lines]
                                    if len(lines)==0:
                                        break
                                    catagories = lines[0]
                                    for x in range (1, len(lines)):
                                        lines[x]=lines[x].split(',')

                            if (d == "D_PATIENTS-" + f + ".txt"):
                                with open(file_name, 'r') as the_file:
                                    lines = the_file.readlines()
                                    lines = [x.strip() for x in lines]
                                    if len(lines)==0:
                                        break
                                    catagories = lines[0]
                                    for x in range (1, len(lines)):
                                        lines[x]=lines[x].split(',')
                            if (d == "DEMOGRAPHIC_DETAIL-" + f + ".txt"):
                                with open(file_name, 'r') as the_file:
                                    lines = the_file.readlines()
                                    lines = [x.strip() for x in lines]
                                    if len(lines)==0:
                                        break
                                    catagories = lines[0]
                                    for x in range (1, len(lines)):
                                        lines[x]=lines[x].split(',')


if __name__ == "__main__":
    read()

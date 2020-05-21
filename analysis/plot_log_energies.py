#!/bin/python
############################################################## 
# Author:               John Vant                            #
# Email:              jvant@asu.edu                          #
# Affiliation:   ASU Biodesign Institute                     #
# Date Created:          200504                              #
############################################################## 
# Usage:                                                     #
############################################################## 
# Notes:                                                     #
############################################################## 
# Import modules #
import sys
import os
import re
import matplotlib.pyplot as plt
import numpy as np


ELabels = ["ETITLE:", "TS", "BOND", "ANGLE", "DIHED", "IMPRP","ELECT","VDW","BOUNDARY","MISC","KINETIC","TOTAL","TEMP","POTENTIAL","TOTAL3","TEMPAVG","PRESSURE","GPRESSURE","VOLUME","PRESSAVG","GPRESSAVG"]

def mymkdir(mydir):
    if not os.path.exists(mydir):
        os.mkdir(mydir)

def scrape_log(logfile):
    print("Scrapping log file: ", os.path.basename(logfile))
    regex = "ENERGY:  "
    Energies = {key: [] for key in ELabels}
    with open(logfile, "r") as file:
        for line in file:
            if re.search(regex,line):
                groups = line.split()
                [ Energies[ELabels[i]].append(groups[i]) for i in range(len(ELabels))]
    return Energies

def plotEnergies(logfile,Logdict):
    exclude = 5
    filename = os.path.basename(logfile)
    fig, axs = plt.subplots(5,4, figsize=[15, 15],sharex=True)
    count=2
    Time = [float(i) for i in Logdict["TS"]][exclude:]
    for ax in np.ndarray.flatten(axs):
        key = ELabels[count]
        data = [float(i) for i in Logdict[key]][exclude:]
        myavg = np.average(data)
        print("Plotting ", key)
        ax.plot(Time,data)
        ax.axhline(myavg,linewidth=2,color='k')
        ax.text(0.25,0.9,"%04.3f" % myavg, horizontalalignment='center',verticalalignment='center', transform=ax.transAxes,fontsize=15)
        ax.set_ylabel(key)
        count+=1
        if count == 21:
            print('breaking')
            break
        plt.tight_layout()
    mymkdir("plots")
#    fig.savefig(F"./plots/{filename}.png")

for arg in sys.argv[1:]:
    plotEnergies(arg, scrape_log(arg))
plt.show()
#exit()

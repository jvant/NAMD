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


ELablesLong = ["ETITLE:", "TS", "BOND", "ANGLE", "DIHED", "IMPRP","ELECT","VDW","BOUNDARY","MISC","KINETIC","TOTAL","TEMP","POTENTIAL","TOTAL3","TEMPAVG","PRESSURE","GPRESSURE","VOLUME","PRESSAVG","GPRESSAVG"]
ELablesShort = ["ETITLE:", "TS", "BOND", "ANGLE", "DIHED", "IMPRP", "ELECT", "VDW", "BOUNDARY", "MISC", "KINETIC", "TOTAL", "TEMP", "POTENTIAL", "TOTAL3", "TEMPAVG"]
def mymkdir(mydir):
    if not os.path.exists(mydir):
        os.mkdir(mydir)

def scrape_log(logfile):
    print("Scrapping log file: ", os.path.basename(logfile))
    regex = "ENERGY:  "
    # Count columns
    with open(logfile, "r") as file:
        for line in file:
            if re.search(regex,line):
                Cols = len(line.split())
                break
    if Cols == 16:
        ELables = ELablesShort    
    else:
        ELables = ELablesLong    
    Energies = {key: [] for key in ELables}
    
    with open(logfile, "r") as file:
        for line in file:
            if re.search(regex,line):
                groups = line.split()
                print(groups)
                # print(len(ELables),len(groups))
                [ Energies[ELables[i]].append(groups[i]) for i in range(len(ELables))]
    return Energies

def plotEnergies(logfile,Logdict):
    if len(Logdict) == 16:
        ELables = ELablesShort
        Cols = 16
    else:
        ELables = ELablesLong
        Cols = len(Logdict)
    exclude = 5
    filename = os.path.basename(logfile)
    fig, axs = plt.subplots(5,4, figsize=[15, 15],sharex=True)
    count=2
    Time = [float(i) for i in Logdict["TS"]][exclude:]
    for ax in np.ndarray.flatten(axs):
        key = ELables[count]
        data = [float(i) for i in Logdict[key]][exclude:]
        myavg = np.average(data)
        print("Plotting ", key)
        ax.plot(Time,data)
        ax.axhline(myavg,linewidth=2,color='k')
        ax.text(0.25,0.9,"%04.3f" % myavg, horizontalalignment='center',verticalalignment='center', transform=ax.transAxes,fontsize=15)
        ax.set_ylabel(key)
        count+=1
        if count == Cols:
            print('breaking')
            break
        plt.tight_layout()
    mymkdir("plots")
#    fig.savefig(F"./plots/{filename}.png")

for arg in sys.argv[1:]:
    plotEnergies(arg, scrape_log(arg))
plt.show()
#exit()

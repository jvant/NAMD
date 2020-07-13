#!/usr/bin/env python
############################################################## 
# Author:               John Vant 
# Email:              jvant@asu.edu 
# Affiliation:   ASU Biodesign Institute 
# Date Created:          200523
############################################################## 
# Usage: 
############################################################## 
# Notes: 
############################################################## 
# Import modules #
import sys
import time
import subprocess
import matplotlib.pyplot as plt
import numpy as np

def rmsd(PSFFile, DCDFile, SelText):
    fout = open("rmsd.tcl", "w")
    fout.write('''set PSFFile %s
set DCDFile %s
set SelText "%s"
'''% (PSFFile, DCDFile, SelText))
    fout.write('''
mol new $PSFFile
mol addfile $DCDFile waitfor -1
set ref [atomselect top $SelText frame 0]
set comp [atomselect top $SelText]
set numfrm [molinfo top get numframes]
set outfile [open "rmsd.dat" w]
for {set frame 0} {$frame < $numfrm} {incr frame} {
    $comp frame $frame
    $comp move [measure fit $comp $ref]
    puts $outfile [measure rmsd $comp $ref]
}
close $outfile
exit
    ''')
    p1 = subprocess.Popen("vmd -dispdev text -e rmsd.tcl", shell=True)
#    time.sleep(10) 
#    p1 = subprocess.check_output(["vmd", "-dispdev text -e rmsd.tcl"])
    # print(p1.stdout)
    # while (p1.stdout == 'None'):
    #     time.sleep(5) 
    # print("stdout is now: ", p1.stdout)

def plotRMSD_Rg():
    filename = "rmsd.dat"
    fig, axs = plt.subplots(1,1, figsize=[10, 10],sharex=True)
    ax = axs
    data = np.loadtxt(filename)
    myavg = np.average(data)
    ax.plot(data)
    ax.axhline(myavg,linewidth=2,color='k')
    ax.text(0.25,0.9,"%04.3f" % myavg, horizontalalignment='center',verticalalignment='center', transform=ax.transAxes,fontsize=15)
#    mymkdir("plots")
#    fig.savefig(F"./plots/{filename}.png")


rmsd(sys.argv[1],sys.argv[2],"noh and not ion and not water")
plotRMSD_Rg()
plt.show()

#!/bin/bash

# Load Modules
module load vmd/1.9.3

# Set system dir location
sysdir="../"

# Set systems to analyze
#systems=(RC1-1 RC1-10 RC1-20 RC1-30 RC1-40 RC1-50 RC2-1 RC2-10 RC2-20 RC2-30 RC2-40 RC2-50)
systems=(RC1-17_RC2-20 RC1-22_RC2-11 RC1-31_RC2-29)

# Start Job Control
### Set 0
systems=(RC1-17_RC2-29  RC1-19_RC2-31  RC1-22_RC2-8   RC1-28_RC2-21  RC1-30_RC2-27 RC1-18_RC2-18 RC1-20_RC2-13  RC1-22_RC2-9   RC1-28_RC2-22  RC1-30_RC2-28)
### Set 1
# systems=(RC1-17_RC2-20     RC1-18_RC2-19  RC1-20_RC2-14  RC1-23_RC2-32  RC1-28_RC2-23  RC1-30_RC2-29 RC1-17_RC2-21     RC1-18_RC2-20  RC1-20_RC2-15  RC1-24_RC2-32)
### Set 2
# systems=(RC1-28_RC2-24  RC1-30_RC2-30 RC1-17_RC2-22     RC1-18_RC2-29  RC1-20_RC2-31  RC1-25_RC2-32  RC1-28_RC2-30  RC1-31_RC2-28 RC1-17_RC2-23     RC1-18_RC2-30)
### Set 3
# systems=(RC1-21_RC2-12  RC1-26_RC2-32  RC1-28_RC2-31  RC1-31_RC2-29 RC1-17_RC2-24     RC1-19_RC2-15  RC1-21_RC2-31  RC1-27_RC2-18  RC1-29_RC2-24 RC1-17_RC2-25)
### set 4
# systems=(RC1-19_RC2-16  RC1-22_RC2-10  RC1-27_RC2-19  RC1-29_RC2-25 RC1-17_RC2-26 RC1-19_RC2-17  RC1-22_RC2-11  RC1-27_RC2-20  RC1-29_RC2-26 RC1-17_RC2-27)
### set 5 
# systems=(RC1-19_RC2-18  RC1-22_RC2-31  RC1-27_RC2-21  RC1-29_RC2-30 RC1-17_RC2-28 RC1-19_RC2-30  RC1-22_RC2-32  RC1-27_RC2-31  RC1-30_RC2-26)


# Loop through systems
echo "system rg_xy rg_z " > rg.dat
for sys in ${systems[@]}; do
    mypath=$sysdir/$sys
    vmd -dispdev text -e Rg_xy-n-z.tcl -args $mypath/my.psf $mypath/my.pdb $sys $mypath/mdff-ca-0.dcd $mypath/mdff-ca-1.dcd $mypath/mdff-ca-2.dcd
done

cat rg.dat

exit

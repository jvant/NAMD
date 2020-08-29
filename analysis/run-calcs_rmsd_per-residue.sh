#!/bin/bash

# Load Modules
module load vmd/1.9.3

# Set system dir location
sysdir="../"

# Loop through systems
for sys in ${systems[@]}; do
    mypath=$sysdir/$sys
    vmd -dispdev text -e Rg_xy-n-z.tcl -args $mypath/my.psf $mypath/my.pdb $sys $mypath/mdff-ca-0.dcd $mypath/mdff-ca-1.dcd $mypath/mdff-ca-2.dcd
done


exit

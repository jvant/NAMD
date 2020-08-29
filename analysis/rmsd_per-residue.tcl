#!/usr/bin/env vmd
############################################################## 
# Author:               John Vant 
# Email:              jvant@asu.edu 
# Affiliation:   ASU Biodesign Institute 
# Date Created:          200523
############################################################## 
# Usage: vmd -dispdev text -e rmsd_per-residue.tcl -args <System name> <PSF file> <DCD file 1> [DCD file 2] ...
############################################################## 
# Notes: 
############################################################## 
# Functions
proc align { refmolid mymolid seltext } { 
    set refselfit [atomselect $refmolid $seltext frame 0]
    set myselfit [atomselect $mymolid $seltext]
    set myselall [atomselect $mymolid all]
    set nf [molinfo $mymolid get numframes]
    for {set i 0} {$i < $nf} {incr i} {
	$myselall frame $i
	$myselfit frame $i
	$myselall move [measure fit $myselfit $refselfit]
    }
    $myselall delete
    $myselfit delete
    $refselfit delete
    return
}

# Script arguments
set SYS [lindex $argv 0]
set PSF [lindex $argv 1]
set DCD [lrange $argv 2 end]

# Load data
mol new $PSF
foreach mydcd $DCD {
    mol addfile $mydcd waitfor -1
}

# set defaults for analysis
set myMolID [molinfo top]
set numFrames [molinfo $myMolID get numframes]
set resids [[atomselect $myMolID "protein and name CA"] get resid]
set selall [atomselect $myMolID "all"]

# Align all structures
align $myMolID $myMolID "protein and name CA"

# Open file for writing RMSD data
set outfile [open "rmsd_per-residue.dat" w]
puts $outfile $resids ;# Title for each column

puts "Entering the loop"
for {set i 0} {$i <= $numFrames} {incr i} {
    $selall frame $i
    set myRMSDvalues [list " "]
    foreach myresid $resids {
	append myRMSDvalue [measure rmsd \
			     [atomselect $myMolID "protein and resid $myresid" frame 0] \
			     [atomselect $myMolID "protein and resid $myresid" frame $i]]
    }
    puts $outfile $myRMSDvalues
    puts "Finished with frame $i"
}
close $outfile

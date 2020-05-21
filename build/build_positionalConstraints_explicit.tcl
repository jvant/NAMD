#!/usr/bin/env vmd

############################################################## 
# 
# Author:               John Vant 
# Email:              jvant@asu.edu 
# Affiliation:   ASU Biodesign Institute 
# Date Created:          200303
# 
############################################################## 
# 
# Usage: 
# 
############################################################## 
# 
# Notes: 
# 
############################################################## 
# PDBs you wish to merge
set mypdbs {chainCH.pdb chainP.pdb}
# Outputname
set cmstr 1cza_full

package require psfgen
resetpsf
set toppar_path ./toppar

topology $toppar_path/top_all36_prot.rtf
topology $toppar_path/top_all36_na.rtf
topology $toppar_path/top_all36_carb.rtf
topology $toppar_path/top_all36_carb_mod.rtf
topology $toppar_path/top_all36_cgenff.rtf
topology $toppar_path/G6P_wH.rtf
topology $toppar_path/toppar_all36_carb_glycopeptide.str
topology $toppar_path/toppar_water_ions_namd.str
topology $toppar_path/toppar_water_ions_namd_mod.str
topology $toppar_path/toppar_all36_prot_na_combined.str

pdbalias residue HIS HSD


set nseg 1
foreach pdb $mypdbs {
  set segid V$nseg 
    segment $segid { 
    pdb $pdb 
    } 
  coordpdb $pdb $segid
  incr nseg
} 
guesscoord
writepsf Tmp.psf
writepdb Tmp.pdb

package require solvate
solvate Tmp.psf Tmp.pdb -t 30 -o Tmp_solv

package require autoionize
autoionize -psf Tmp_solv.psf -pdb Tmp_solv.pdb -neutralize -o ./$cmstr-solv_ion
resetpsf

#Calculate PBC size and write file w/ values
set sel [atomselect top water]
set var_minmax [measure minmax $sel]
set var_cen [measure center $sel]

set var_size [vecsub [lindex $var_minmax 1] [lindex $var_minmax 0]]

set outfile [open "PBC_Values.str" w]
puts $outfile $var_size
puts $outfile $var_cen
close $outfile

##############################################################
# Positional restraints
# Make selections
set selall [atomselect top all]
set selp [atomselect top protein]
set selbb [atomselect top "backbone and protein"]
set selnotbb [atomselect top "not backbone and noh and protein"]
set selligs [atomselect top "not backbone and noh and not water and not ion"]

# Reset O and B
$selall set occupancy 0
$selall set beta 0

# Set protein O
$selp set occupancy 1

# Contrain ligands
$selligs set occupancy 1
$selligs set beta 1

# Contrain bb
$selbb set beta 1

# Contrain sidechains
$selnotbb set beta 0.5

# Write
$selall writepdb prot_poscons.pdb

#####
# Colvar atoms file
# Reset B
$selall set beta 0

# make selections
set sellig [atomselect top "resid 919 and not water and not ion and not protein and noh"]
set selresid [atomselect top "resid 84 88 209 413 415 449 and protein and noh"]

# set B
$sellig set beta 1
$selresid set beta 2

# Write
$selall writepdb lig_coord.pdb

##############################################################
# Delete temporary files

file delete Tmp_solv.psf Tmp_solv.pdb Tmp.pdb Tmp.psf Tmp_solv.log 

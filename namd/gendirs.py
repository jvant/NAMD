#!/usr/bin/env python

############################################################## 
# Author:               John Vant 
# Email:              jvant@asu.edu 
# Affiliation:   ASU Biodesign Institute 
# Date Created:          200303
############################################################## 
# Usage: 
############################################################## 
# Notes: 
############################################################## 
### Import Modules
import os
import glob

### Conf
script = '''
## Sim Control
#inputname
%s
#outputname
%s
#temperature
set temp                303.15;

## Define Functions
proc get_first_ts { xscfile } {
         set fd [open $xscfile r]
         gets $fd
         gets $fd
         gets $fd line
         set ts [lindex $line 0]
         close $fd
         return $ts
}

## Topology & Structure
structure               my.psf
coordinates             my.pdb

## I/O control
if { [info exists inputname] } {
    set firsttime       [get_first_ts ./$inputname.xsc]
    binCoordinates      $inputname.coor;    # coordinates from last run (binary)
    binVelocities       $inputname.vel;     # velocities from last run (binary)
    extendedSystem      $inputname.xsc;     # cell dimensions from last run (binary)
#    firsttimestep       $firsttime
} else {
    temperature         $temp
}
outputName              $outputname;        # base name for output from this run
restartfreq             500;                # 500 steps = every 1ps
dcdfreq                 5000;
dcdUnitCell             yes;                # the file will contain unit cell info in the style of
xstFreq                 5000;               # XSTFreq: control how often the extended systen configuration
outputEnergies          125;                # 125 steps = every 0.25ps
outputTiming            1000;               # The number of timesteps between each timing output shows

## Force-Field Parameters
paraTypeCharmm      on;                 # We're using charmm type parameter file(s)
parameters          charmm/par_all36m_prot.prm
parameters          charmm/par_all36_na.prm
parameters          charmm/par_all36_carb.prm
parameters          charmm/par_all36_lipid.prm
parameters          charmm/par_all36_cgenff.prm
parameters          charmm/toppar_water_ions_namd.str
parameters          charmm/AMP.par
parameters          charmm/toppar_dum_noble_gases.str
parameters          charmm/toppar_all36_prot_d_aminoacids.str
parameters          charmm/toppar_all36_prot_fluoro_alkanes.str
parameters          charmm/toppar_all36_prot_heme.str
parameters          charmm/toppar_all36_prot_na_combined.str
parameters          charmm/toppar_all36_prot_retinol.str
parameters          charmm/toppar_all36_na_nad_ppi.str
parameters          charmm/toppar_all36_na_rna_modified.str
parameters          charmm/toppar_all36_lipid_bacterial.str
parameters          charmm/toppar_all36_lipid_cardiolipin.str
parameters          charmm/toppar_all36_lipid_cholesterol.str
parameters          charmm/toppar_all36_lipid_inositol.str
parameters          charmm/toppar_all36_lipid_lps.str
parameters          charmm/toppar_all36_lipid_miscellaneous.str
parameters          charmm/toppar_all36_lipid_model.str
parameters          charmm/toppar_all36_lipid_prot.str
parameters          charmm/toppar_all36_lipid_pyrophosphate.str
parameters          charmm/toppar_all36_lipid_sphingo.str
parameters          charmm/toppar_all36_lipid_yeast.str
parameters          charmm/toppar_all36_lipid_hmmm.str
parameters          charmm/toppar_all36_lipid_detergent.str
parameters          charmm/toppar_all36_carb_glycolipid.str
parameters          charmm/toppar_all36_carb_glycopeptide.str
parameters          charmm/toppar_all36_carb_imlab.str

##Force field modifications
exclude scaled1-4
1-4scaling 1.0
dielectric 1.0
if { $GBISON } {
    gbis                on
    switching           on
    VDWForceSwitching   on
    alphacutoff         14.
    switchdist          15.
    cutoff              16.
    pairlistdist        17.
    ionconcentration    0.1
    solventDielectric   80.0
    sasa                on
} else {
    switchdist          9.
    cutoff              10.
    pairlistdist        11.
    if { ! [info exists inputname] } {
	#  Slurp up the data file
	set fp [open "./PBC_Values.str" r]
	set file_data [read $fp]
	close $fp
	set data [split $file_data "\n"]
	set a [lindex $data 0 0]
	set b [lindex $data 0 1]
	set c [lindex $data 0 2]
	set xcen [lindex $data 1 0]
	set ycen [lindex $data 1 1]
	set zcen [lindex $data 1 2]
	cellBasisVector1     $a   0.0   0.0;        # vector to the next image
	cellBasisVector2    0.0    $b   0.0;
	cellBasisVector3    0.0   0.0    $c;
	cellOrigin          $xcen $ycen $zcen;        # the *center* of the cell
    }
}
stepspercycle       20
margin              2.0
rigidBonds          ALL
timestep            2.0

## Integrator Parameters
nonbondedFreq           1;                  # nonbonded forces every step
fullElectFrequency      1;                  # PME every step

## Constant Temperature Control ONLY DURING EQUILB
reassignFreq            500;                # reassignFreq:  use this to reassign velocity every 500 steps
reassignTemp            $temp;
langevin                on
langevinDamping         1.0
langevinTemp            $temp
langevinHydrogen        off

## Customization
%s

## Run
%s
%s
'''

### Stings Subs
INPUTNAME = '''
set inputname           %s;
'''
OUTPUTNAME = '''
#set step                %s;
set outputname          %s;
'''
MINIMIZE = '''
minimize                %d
'''
RUN = '''
run                     %d
'''
CONSTRAINTS = '''
constraints             on
consexp                 2
consref                 ./prot_poscons.pdb
conskfile               ./prot_poscons.pdb
conskcol                B
constraintScaling       %s
'''
COLVAR1 = '''
colvars on
cv config "
colvar {
    name COORD
    coordnum {
        group1 {
            atomsFile      lig_coord.pdb
            atomsCol       B
            atomsColValue  1
        }
        group2 {
            atomsFile      lig_coord.pdb
            atomsCol       B
            atomsColValue  2
        }
    }
}
"
cv config "
harmonic {
    name harm
    colvars $cvname
    centers $initvalue
    forceConstant 0.01
    outputAccumulatedWork on
    outputCenters on
}
"
'''
def mymkdir(s):
	if not os.path.exists(s):
		os.makedirs(s)
def mysymlink(source, dest):
	if not os.path.exists(dest):
		os.symlink(source, dest)
def setparam(param,value):
        return param % value

def makeconf(step):
        if (step == 0):
                conf = script % ( "#first step :)",\
				  setparam(OUTPUTNAME, "step%s" % step) ),\
                                  "#no customization",\
                                  setparam(MINIMIZE, 1000),\
                                  setparam(RUN, 500000) )
        elif (step == 1):
                conf = script % ( setparam(OUTPUTNAME, "step%s" % step),\
                                  setparam(INPUTNAME, "step%s.restart" % (step - 1)),\
                                  "#no customization",\
                                  "#no minimize",\
                                  setparam(RUN, 500000) )
        else:
                conf = script % ( setparam(OUTPUTNAME,"step%s" % step),\
                                  setparam(INPUTNAME,"step%s.restart" % (step - 1)),\
                                  "#no customization",\
                                  "#no minimize",\
                                  setparam(RUN, 500000) )
        return conf


def createsys(ligname,sysname):
        mymkdir("./%s-%s" % (ligname, sysname))
        os.chdir("./%s-%s" % (ligname, sysname))
        mysymlink("../../build/%s-ligand-mod/%s_A_aligned_w-ligand.psf" % (ligname, sysname), "my.psf")
        mysymlink("../../build/%s-ligand-mod/%s_A_aligned_w-ligand.pdb" % (ligname, sysname), "my.pdb")
        mysymlink("../../build/%s-ligand-mod/%s_A_aligned_w-ligand-consfile.pdb" % (ligname, sysname), "prot_poscons.pdb")
        mysymlink("../../%s" % "charmm", "toppar")
        for i in range(1,5):
                fout = open("step%d.namd" % i, "w")
                fout.write(makeconf(i))
                fout.close()
        os.chdir("../")

for lig in ["4ake-dock-2", "4ake-dock-9"]:
        for mysys in ["1ake", "4ake"]:
                createsys(lig,mysys)

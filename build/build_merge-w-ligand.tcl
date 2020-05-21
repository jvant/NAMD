##
## Load and merge all of the PDB files in a given directory
## Usage: source mergepdbs.txt
## Output is written to "mergedpdb.psf" and "mergedpdb.pdb"
##
package require psfgen
## Load topology
topology ../charmm/top_all36_prot.rtf
topology ../charmm/top_all36_cgenff.rtf
topology ../charmm/AMP.rtf
topology ../charmm/toppar_water_ions_namd.str

## Provide Aliases
pdbalias residue HIS HSD
pdbalias residue HOH TIP3
pdbalias residue AMP LIG
pdbalias residue ATP3 ATP
pdbalias residue MG30 MG
set ligfile "4ake-dock-9-ligand-mod.pdb"
set outdir [file rootname $ligfile]
file mkdir $outdir
set indir "Input"

## Loop through psfgen of 1ake and 4ake
foreach mypdb { "1ake_A_aligned.pdb" "4ake_A_aligned.pdb" } {
    resetpsf
    set nseg 1
    foreach pdb [list $indir/$mypdb  "$indir/$ligfile"] {
	set segid V$nseg 
	segment $segid { 
	    first NONE
	    last NONE
	    pdb $pdb 
	} 
	coordpdb $pdb $segid
	incr nseg
    } 
    guesscoord

    set molname [file rootname $mypdb]_w-ligand
    writepsf $outdir/$molname.psf
    writepdb $outdir/$molname.pdb
    mol new $outdir/$molname.psf
    mol addfile $outdir/$molname.pdb
}

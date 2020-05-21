package require autopsf
package require mdff
package require ssrestraints
package require cispeptide
package require chirality
package require volutil

# Set prefix name
set molname 5x29

# Build structure
resetpsf
mol new model4_align.pdb
autopsf -mol [molinfo list] -protein -top ../charmm/top_all36_prot.rtf -prefix ${molname}
mv ${molname}_formatted_autopsf.psf ${molname}.psf
mv ${molname}_formatted_autopsf.pdb ${molname}.pdb
mol delete all

#Start making maps
set seltxtnoh "noh and resid 8 to 65 and not resid 40 43 44 55 56"
set seltxtbb "backbone and resid 8 to 65 and not resid 40 43 44 55 56"

for {set ref 0} {$ref <= 15} {incr ref} {

    mol new chainA_f${ref}_align.pdb
    set sel [atomselect top $seltxtnoh]

    #Generate simulated maps
    for { set res 1 } { $res <= 5 } { incr res 2 } {
	set name "map_${ref}-${res}"
	mdff sim $sel -res $res -o $name.dx
	mdff griddx -i $name.dx -o ${name}-grid.dx
    }
    puts "================================"
    puts "am i coming out of the loop"
}

#restraints time
ssrestraints -psf $molname.psf -pdb $molname.pdb -o $molname-ssrestraints.txt -hbonds
cispeptide restrain -o $molname-cispeptide.txt
chirality restrain -o $molname-chirality.txt


mdff gridpdb -psf $molname.psf -pdb $molname.pdb -seltext $seltxtnoh -o gridpdb-noh.pdb
mdff gridpdb -psf $molname.psf -pdb $molname.pdb -seltext $seltxtbb -o gridpdb-bb.pdb

exit

package require autopsf
package require mdff
package require ssrestraints
package require cispeptide
package require chirality
package require volutil
# Notes
# ref refers to new template being created
# pos refers to the old template where coordinates will be extracted

set systems [list 1cza_w_G6P]
set myinput Input
foreach sys $systems {
    set outdir $sys-out
    if { ! [file exists $outdir]} {
	file mkdir $outdir
    }

    # Create selection to target
    set fromres 20
    set tores 910
    set seltextCAog "protein and name CA and resid $fromres to $tores"

    set myselnames [list "noh" "bb" "ca"]
    set count 0
    foreach selset {"noh" "backbone" "name CA"} {
	mol new $myinput/$sys.psf
	mol addfile $myinput/$sys.coor
	set refid [molinfo top]
	set selref [atomselect $refid all]
	$selref set beta 0
	$selref set occupancy 0

	# Grab resids
	set myresids [[atomselect $refid "$seltextCAog"] get resid]

	# Load pos pdb
	mol new $myinput/${sys}_template.pdb
	set posid [molinfo top]

	# Error check
	if {[[atomselect $posid $seltextCAog] num] != [[atomselect $refid $seltextCAog] num]} {
	    puts "Pos num: [[atomselect $posid $seltextCAog] num] does not equal Ref num: [[atomselect $refid $seltextCAog] num]"
	}
	
	# Align Pos to Ref
	[atomselect $posid all] move [measure fit [atomselect $posid $seltextCAog] [atomselect $refid "$seltextCAog"]]

	# loop through atoms to create new ref
	foreach myresid $myresids {
	    set mynames [[atomselect $refid "protein and resid $myresid and $selset"] get name]
	    foreach myname $mynames {
		puts "==================="
		set newseltextref "protein and resid $myresid and name $myname"
		# set posresid [expr $myresid - $sub]
		set newseltextpos "protein and resid $myresid and name $myname"
		set refatom [atomselect $refid $newseltextref]
		set newpos [[atomselect $posid $newseltextpos] get {x y z}]
		puts "the seltext is $newseltextref"
		puts "The ref selection has [$refatom num] atoms"
		puts "The new position has [[atomselect $posid $newseltextpos] num] atoms"
		puts "There newpos atom is at: $newpos"
		$refatom set {x y z} $newpos
		$refatom set beta 1
		$refatom set occupancy 1
	    }
	}
	# Write Ref file
	$selref writepdb $outdir/ref-[lindex $myselnames $count].pdb
	incr count
	mol delete all
    }
    # Final steps
    mol new $myinput/$sys.psf
    mol addfile $myinput/$sys.coor

    # Write PBC file
    set sel [atomselect top water]
    set var_minmax [measure minmax $sel]
    set var_cen [measure center $sel]
    set var_size [vecsub [lindex $var_minmax 1] [lindex $var_minmax 0]]
    set outfile [open "./${outdir}/PBC_Values.str" w]
    puts $outfile $var_size
    puts $outfile $var_cen
    close $outfile

    # Write clean PSF and PDB
    set sel [atomselect top all]
    $sel writepsf ${outdir}/my.psf
    $sel writepdb ${outdir}/my.pdb

}
exit

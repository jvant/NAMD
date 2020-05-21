package require autopsf
package require mdff
package require ssrestraints
package require cispeptide
package require chirality
package require volutil

# Set prefix name
set molname my
set inputpsf ./Starting_Models/Alec_unstruct.psf
set inputpdb ./Starting_Models/Alec_unstruct.coor

# Build structure
resetpsf
# mol new TM_unstruct.pdb 
# autopsf -mol [molinfo list] -protein -top ../charmm/top_all36_prot.rtf -prefix ${molname}
# mv ${molname}_formatted_autopsf.psf ${molname}.psf
# mv ${molname}_formatted_autopsf.pdb ${molname}.pdb
# mol delete all

# Set new postions for reference files.
# TM domain only
set fromres 10
set tores 37
set seltextCAog "protein and resid $fromres to $tores and not name OXT and noh and name CA"
for {set i 0} {$i <= 15} {incr i} {

    set myselnames [list "noh" "bb" "ca"]
    set count 0
    foreach selset {"noh" "backbone" "name CA"} {
	mol new $inputpsf
	mol addfile $inputpdb
	set refid [molinfo top]
	set selref [atomselect $refid all]
	$selref set beta 0
	$selref set occupancy 0
	set count2 0
	set sub 0
	foreach seg {"A" "B" "C" "D" "E"} {
	    set seltextCA "protein and resid ${count2}$fromres to ${count2}$tores and not name OXT and noh and name CA"
	    set myresids [[atomselect $refid "$seltextCA and segname PRO$seg"] get resid]

	    
#	    mol new ./Abhignas_templates/chainA_mod.pdb
	    mol new 5x29_templates/chainA_f${i}_align_cmod.pdb
	    set posid [molinfo top]
	    puts [[atomselect $posid $seltextCAog] num]
	    puts "$seltextCA and segname PRO$seg"
	    puts [[atomselect $refid "$seltextCA and segname PRO$seg"] num]
	    [atomselect $posid all] move [measure fit [atomselect $posid $seltextCAog] [atomselect $refid "$seltextCA and segname PRO$seg"]]
	    foreach myresid $myresids {
		set mynames [[atomselect $refid "protein and resid $myresid and $selset and segname PRO$seg"] get name]
		foreach myname $mynames {
		    puts "==================="
		    set newseltextref "protein and resid $myresid and name $myname"
		    set posresid [expr $myresid - $sub]
		    set newseltextpos "protein and resid $posresid and name $myname"
		    set newpos [[atomselect $posid $newseltextpos] get {x y z}]
		    set refatom [atomselect $refid $newseltextref]
		    puts "the seltext is $newseltextref"
		    puts "The ref selection has [$refatom num] atoms"
		    puts "The new position has [[atomselect $posid $newseltextpos] num] atoms"
		    puts "There newpos atom is at: $newpos"
		    $refatom set {x y z} $newpos
		    puts "fail here?"
		    $refatom set beta 1
		    $refatom set occupancy 1
		}
	    }
	    incr count2
	    incr sub 100
	}
	$selref num
	$selref writepdb ./ref_pdbs/ref$i-[lindex $myselnames $count].pdb
	incr count
	mol delete all
    }
}

# Final steps
mol new $inputpsf 
mol addfile $inputpdb 

# Write PBC file
set sel [atomselect top water]
set var_minmax [measure minmax $sel]
set var_cen [measure center $sel]
set var_size [vecsub [lindex $var_minmax 1] [lindex $var_minmax 0]]
set outfile [open "./system_out/PBC_Values.str" w]
puts $outfile $var_size
puts $outfile $var_cen
close $outfile

set sel [atomselect top all]
$sel writepsf system_out/my.psf
$sel writepdb system_out/my.pdb

exit

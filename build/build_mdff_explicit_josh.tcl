package require autopsf
package require mdff
package require solvate
package require ssrestraints
package require cispeptide
package require chirality
package require volutil
topology ../charmm/top_all36_prot.rtf
topology ../charmm/toppar_water_ions_namd.str
mol new 1oao.pdb
set molname cmdh
set C [atomselect top "chain C and backbone and resid >=2"]
set D [atomselect top "chain D and backbone and resid >=2"]
$C moveby [vecscale -1 [measure center $C]]
$D move [measure fit $D $C]
$C writepdb C.pdb
$D writepdb D.pdb
mol delete [molinfo list]
foreach chain [list C D] statename [list "closed" "open"] {
	resetpsf
	mol new $chain.pdb
	autopsf -mol [molinfo list] -protein -top ../charmm/top_all36_prot.rtf -prefix $statename
	foreach mid [molinfo list] {
		mol delete $mid
	}
}
mv open_formatted_autopsf.psf $molname.psf
mv open_formatted_autopsf.pdb open.pdb
mv closed_formatted_autopsf.pdb closed.pdb
#exit
mol new $molname.psf
mol addfile open.pdb
mol addfile closed.pdb
#align open and closed structures.
set opensel [atomselect top "all" frame 0]
set closedsel [atomselect top "all" frame 1]
set openminmax [measure minmax $opensel]
set closedminmax [measure minmax $closedsel]
set waterlowbound [list ]
set waterhighbound [list ]
for { set i 0 } { $i < 3 } { incr i } {
	lappend waterlowbound [expr { -15 + min([lindex $openminmax 0 $i],[lindex $closedminmax 0 $i])}]
}
for { set i 0 } { $i < 3 } { incr i } {
	lappend waterhighbound [expr { 15 + max([lindex $openminmax 1 $i],[lindex $closedminmax 1 $i])}]
}
set waterbound [list $waterlowbound $waterhighbound]
set openselnoh [atomselect top "noh" frame 0]
set closedselnoh [atomselect top "noh" frame 1]
$closedsel move [measure fit $closedsel $opensel]
$closedsel writepdb closed.pdb
# calculate Center of mass for positional contraint
set com_closed [measure center $closedselnoh weight mass]
set com_open [measure center $openselnoh weight mass]
foreach i {0 1 2} {
    append mid_com \
	[expr [expr [lindex $com_closed $i] + [lindex $com_open $i]] / 2 ] " "}
puts $mid_com
set mid_com [vecscale 0.5 [vecadd $com_closed $com_open]]
puts $mid_com
set "outfile" [open "com.dat" w]
puts $outfile $mid_com
close $outfile
#Generate simulated maps
# foreach state [list "open" "closed"] sel [list $opensel $closedsel] {
# 	for { set res 1 } { $res <= 11 } { incr res 2 } {
# 		set name "${state}-${res}"
# 		mdff sim $sel -res $res -o $name.dx
# 		mdff griddx -i $name.dx -o ${name}-grid.dx
# 		volutil -smult -1 -o ${name}-invertedgrid.dx ${name}-grid.dx
# 		volutil -sadd 1 -o ${name}-flippedgrid.dx ${name}-invertedgrid.dx
# 		rm ${name}-invertedgrid.dx
# 	}
# }
package require solvate
package require autoionize
foreach state {"closed" "open"} {
    #Solvate
    solvate ${molname}.psf ${state}.pdb -minmax $waterbound -o ${state}_solv

    #Ionize
    autoionize -psf ${state}_solv.psf -pdb ${state}_solv.pdb -neutralize -o ./${state}_solv-ion

    #restraints time
    ssrestraints -psf ${state}_solv-ion.psf -pdb ${state}_solv-ion.pdb \
	-o ${state}-ssrestraints.txt -hbonds
    cispeptide restrain -o ${state}-cispeptide.txt
    chirality restrain -o ${state}-chirality.txt

    #grid pdbs
    mdff gridpdb -psf ${state}_solv-ion.psf -pdb ${state}_solv-ion.pdb \
	-seltext "protein and noh" -o ${state}_gridpdb-noh.pdb
    mdff gridpdb -psf ${state}_solv-ion.psf -pdb ${state}_solv-ion.pdb \
	-seltext "backbone" -o ${state}_gridpdb-bb.pdb
    puts "======================="
    puts "bout to del"

    foreach mid [molinfo list] {
	mol delete $mid
    }
#Calculate PBC size and write file w/ values
    puts "======================="
    puts "bout to calc PBC"
    mol new ${state}_solv-ion.psf
    mol addfile ${state}_solv-ion.pdb
    set sel [atomselect top water]
    set var_minmax [measure minmax $sel]
    set var_cen [measure center $sel]
    set var_size [vecsub [lindex $var_minmax 1] [lindex $var_minmax 0]]
    set outfile [open "PBC_Values.str" w]
    puts $outfile $var_size
    puts $outfile $var_cen
    close $outfile
}
exit

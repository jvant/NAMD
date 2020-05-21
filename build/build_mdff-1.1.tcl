package require autopsf
package require mdff
package require ssrestraints
package require cispeptide
package require chirality
package require volutil
../charmm/top_all36_prot.rtf

set molname adk

foreach pdbname [list 1ake 4ake] statename [list "closed" "open"] {
	resetpsf
	mol new $pdbname.pdb
	set sel [atomselect top "chain A"]
	$sel writepdb tmp.pdb
	mol delete top
	mol new tmp.pdb
	autopsf -mol [molinfo list] -protein -top ../charmm/top_all36_prot.rtf -prefix $statename
	foreach mid [molinfo list] {
		mol delete $mid
	}
}
mv open_formatted_autopsf.psf $molname.psf
mv open_formatted_autopsf.pdb open.pdb
mv closed_formatted_autopsf.pdb closed.pdb
mol new $molname.psf
mol addfile open.pdb
mol addfile closed.pdb
#align open and closed structures.
set opensel [atomselect top "all" frame 0]
set openselnoh [atomselect top "noh" frame 0]
set closedsel [atomselect top "all" frame 1]
set closedselnoh [atomselect top "noh" frame 1]
$closedsel move [measure fit $closedselnoh $openselnoh]
$closedsel writepdb closed.pdb
# calculate Center of mass for positional contraint
set com_closed [measure center $closedselnoh weight mass]
set com_open [measure center $openselnoh weight mass]
foreach i {0 1 2} {
    append mid_com \
	[expr [expr [lindex $com_closed $i] + [lindex $com_open $i]] / 2 ] " "}
set "outfile" [open "com.dat" w]
puts $outfile $mid_com
close $outfile
#Generate simulated maps
foreach state [list "open" "closed"] sel [list $openselnoh $closedselnoh] {
	for { set res 1 } { $res <= 11 } { incr res 2 } {
		set name "${state}-${res}"
		mdff sim $sel -res $res -o $name.dx
		mdff griddx -i $name.dx -o ${name}-grid.dx
		volutil -smult -1 -o ${name}-invertedgrid.dx ${name}-grid.dx
		volutil -sadd 1 -o ${name}-flippedgrid.dx ${name}-invertedgrid.dx
		rm ${name}-invertedgrid.dx
	}
}
#restraints time
ssrestraints -psf $molname.psf -pdb open.pdb -o $molname-ssrestraints.txt -hbonds
cispeptide restrain -o $molname-cispeptide.txt
chirality restrain -o $molname-chirality.txt

mdff gridpdb -psf $molname.psf -pdb open.pdb -seltext "noh" -o gridpdb-noh.pdb
mdff gridpdb -psf $molname.psf -pdb open.pdb -seltext "backbone" -o gridpdb-bb.pdb

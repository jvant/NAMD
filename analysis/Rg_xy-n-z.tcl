#!/tcl

set PSF [lindex $argv 0]
set PDB [lindex $argv 1]
set SYS [lindex $argv 2]
set DCD [lrange $argv 3 end]


proc gyr_radius_xy {sel} {
  # make sure this is a proper selection and has atoms
  if {[$sel num] <= 0} {
    error "gyr_radius: must have at least one atom in selection"
  }
  # gyration is sqrt( sum((r(i) - r(center_of_mass))^2) / N)
  set com [measure center $sel weight mass]
  puts "$com"
  set com "[lindex $com 0] [lindex $com 1]"
  puts "$com"
  set sum 0
  foreach coord [$sel get {x y}] {
    set sum [vecadd $sum [veclength2 [vecsub $coord $com]]]
  }
  return [expr sqrt($sum / ([$sel num] + 0.0))]
}

proc gyr_radius_z {sel} {
  # make sure this is a proper selection and has atoms
  if {[$sel num] <= 0} {
    error "gyr_radius: must have at least one atom in selection"
  }
  # gyration is sqrt( sum((r(i) - r(center_of_mass))^2) / N)
  set com [measure center $sel weight mass]
  puts "$com"
  set com "[lindex $com 2]"
  puts "$com"
  set sum 0
  foreach coord [$sel get {z}] {
    set sum [vecadd $sum [veclength2 [vecsub $coord $com]]]
  }
  return [expr sqrt($sum / ([$sel num] + 0.0))]
}


# Load seltext
set seltext ""
foreach mychain {A B C} {
    set infile [open "../../build/nice-resids_chain-$mychain.dat" r]
    set file_data [read $infile]
    puts $file_data
    close $infile
    if {$mychain == "C"} {
	append seltext $file_data
    } else {
	append seltext $file_data "or"
    }
}

mol new $PSF
mol addfile $PDB
foreach mydcd $DCD {
    mol addfile $mydcd waitfor -1
}
set nf [molinfo top get numframes]
set nf_analyze [expr {int([expr $nf * .3])}]
set myframes "frame [expr $nf - $nf_analyze] to [expr $nf - 1]"

set mygyr_xy [gyr_radius_xy [atomselect top "$seltext and name CA $myframes"]]
set mygyr_z [gyr_radius_z [atomselect top "$seltext and name CA $myframes"]]

set fo [open rg.dat a]
puts $fo "$SYS $mygyr_xy $mygyr_z"
close $fo
exit

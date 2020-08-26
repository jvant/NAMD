#!/usr/bin/env bash
############################################################## 
# Author:               John Vant 
# Email:              jvant@asu.edu 
# Affiliation:   ASU Biodesign Institute 
# Date Created:          200825
############################################################## 
# Usage: ./htcgpu-sbatch.sh [jobname]
############################################################## 
# Notes: This script is set up to run NAMD gpu simulations.
############################################################## 

### Functions
mysbatch () {
    sbatch \
	--parsable \
	-N $Nodes \
	-n $Cores \
	-t $Time \
	--gres=gpu:$Gpus \
	-o slurm_${cmstr}.log \
	-p $Partition -q $Queue \
	-J ${cmstr} \
	$@
}
### Jobname Argument
if [ -z "$1" ]; then
    echo "Please enter a unique job name";read jobname
else
    jobname=$1
fi

### Set Defaults
Nodes=1				# 1 is the upper limit
Cores=12			# [6/12]
Gpus=2				# [1/2] k20
Partition=rcgpu7
Queue=wildfire
Time=1-4:00			# 5-0:00 is the upper limit for these nodes
threads=$(expr $Cores - $Gpus)


cat <<EOF > tmp-runnamd
#!/bin/bash
module load namd/2.13b1-cuda
namd2 +p${threads} tmd-$i.namd
EOF

mysbatch tmp-runnamd

######
### Uncommit the section below for submitting multiple jobs at the same time with dependencies
######

# Start Job Control
# systems=(1cza_T259A_w_G6P 1cza_OGLCNAC_w_G6P)
# jobid=""

# # Main
# for sys in ${systems[@]}; do
#     cd $sys    
#     for i in {0..2}; do
# 	cmstr=$jobname-$sys-run$i
# 	# NAMD
# 	cat <<EOF > tmp-runnamd
# #!/bin/bash
# module load namd/2.13b1-cuda
# namd2 +p${threads} tmd-$i.namd
# EOF
# 	if [ -z $jobid ];then
# 	    jobid=$(mysbatch tmp-runnamd)
# 	else
# 	    jobid=$(mysbatch -d afterany:$jobid tmp-runnamd)
# 	fi
# 	echo "Job named " $cmstr ", submitted with JOBID: " $jobid
#     done
#     cd -
# done
# exit

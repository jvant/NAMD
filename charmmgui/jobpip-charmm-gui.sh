#!/usr/bin/env bash
##############################################################
# Author:               John Vant
# Email:              jvant@asu.edu
# Affiliation:   ASU Biodesign Institute
# Date Created:          200520
##############################################################
# Usage: ./jobpip.sh <JOB NAME>
##############################################################
# Notes:  If you did not make jobpip.sh executable then bash.
##############################################################
# Define Functions
mysbatch () {
    sbatch \
        --parsable \
        -N $Nodes \
        -n $Cores \
        -t 0-4:00 \
        --gres=gpu:$Gpus \
        -o slurm_${cmstr}.log \
        -p $Partition -q $Queue \
        -J ${cmstr} \
        $@
}
# Jobname Argument
if [ -z "$1" ]; then
    echo "Please enter a unique job name";read jobname
else
    jobname=$1
fi

# Set Defaults
Nodes=1
Cores=10
Gpus=1
Partition=rcgpu7
Queue=normal
threads=$(expr $Cores - $Gpus)

# Start Job Control
jobid=""
# Main (jobs will be run serially in the order you place them)
myconfs=(step4_equilibration.inp step5_production.inp)
for conf in ${myconfs[@]};do
    cmstr=$jobname-${conf%.*}
    test -a tmp-runnamd && rm tmp-runnamd
    cat <<EOF >> tmp-runnamd
#!/bin/bash
module load namd/2.13b1-cuda
namd2 +p${threads} ${conf}
EOF
    if [ -z $jobid ];then ; # test if there is a dependency
        jobid=$(mysbatch tmp-runnamd)
    else
        jobid=$(mysbatch -d afterany:$jobid tmp-runnamd)
    fi
    echo "Job named " $cmstr ", submitted with JOBID: " $jobid
done
exit

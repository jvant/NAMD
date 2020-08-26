#!/bin/bash

# Functions
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
# Jobname Argument
if [ -z "$1" ]; then
    echo "Please enter a unique job name";read jobname
else
    jobname=$1
fi

# Set Defaults
Nodes=1
Cores=20
Gpus=2
Partition=htcgpu
Queue=normal
Time=0-4:00
threads=$(expr $Cores - $Gpus)

# Start Job Control
systems=(1cza_T259A_w_G6P 1cza_OGLCNAC_w_G6P)
jobid=""

# Main
for sys in ${systems[@]}; do
    cd $sys    
    for i in {0..2}; do
	cmstr=$jobname-$sys-run$i
	# NAMD
	cat <<EOF > tmp-runnamd
#!/bin/bash
module load namd/2.13b1-cuda
namd2 +p${threads} tmd-$i.namd
EOF
	if [ -z $jobid ];then
	    jobid=$(mysbatch tmp-runnamd)
	else
	    jobid=$(mysbatch -d afterany:$jobid tmp-runnamd)
	fi
	echo "Job named " $cmstr ", submitted with JOBID: " $jobid
    done
    cd -
done
exit

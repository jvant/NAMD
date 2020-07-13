#!/bin/bash

#SBATCH -n 32
#SBATCH -q asinghargpu1
#SBATCH -p asinghargpu1
#SBATCH --gres=gpu:1
#SBATCH -J REST2asing

module load namd/2.13-mpi
#module load namd/2.13b1-cuda
#module load openmpi/3.0.3-gnu-7x-centos75 

charmrun +p16 namd2 +replicas 16 job0.conf +stdout output_spt_aaqaa3/%d/job0.%d.log

# /packages/NAMD_CVS-2013-07-30_Linux-x86_64-MPI/charmrun +p1 namd2 +replicas 4 rest2_remd.namd +stdout output/%d/job0.%d.log

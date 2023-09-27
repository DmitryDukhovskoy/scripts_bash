#!/bin/bash
#SBATCH -e err
#SBATCH -o out
#SBATCH --account=marine-cpu
### #SBATCH --ntasks=240
#SBATCH --nodes=58
#SBATCH --ntasks-per-node=40
##SBATCH --time=8:00:00
#SBATCH --time=00:30:00
#SBATCH --job-name="08mom6_test"
#SBATCH -q debug
##SBATCH --qos=batch
## 
## Usage: sbatch sub_mom6.sh
set -eux
#echo -n " $( date +%s )," >  job_timestamp.txt
echo -n " $( date +%Y%m%d-%H:%M:%S )," >  job_timestamp.txt

set +x
MACHINE_ID=hera
source ./module-setup.sh
#module use $( pwd -P )
module use $PWD/modulefiles
module load modules.fv3
module list
set -x

echo "Model started:  " `date`

export HEXE=fv3_001.exe
export MPI_TYPE_DEPTH=20
export OMP_STACKSIZE=512M
export OMP_NUM_THREADS=1
export ESMF_RUNTIME_COMPLIANCECHECK=OFF:depth=4
export ESMF_RUNTIME_PROFILE=ON
export ESMF_RUNTIME_PROFILE_OUTPUT="SUMMARY"
export PSM_RANKS_PER_CONTEXT=4
export PSM_SHAREDCONTEXTS=1

# Avoid job errors because of filesystem synchronization delays
sync && sleep 1

#srun --label -n 2320 ./fv3.exe
srun --label -n 2320 ./${HEXE}

echo "Model ended:    " `date`
echo -n " $( date +%s )," >> job_timestamp.txt

#!/bin/bash -l
#SBATCH -e err
#SBATCH -o out
#SBATCH --job-name="sfs_mx025_c192"
#SBATCH --account=sfs-cpu
##SBATCH --qos=normal
#SBATCH --qos=debug
#SBATCH --clusters=c6
#SBATCH --partition=batch
#SBATCH --nodes=5
#SBATCH --ntasks-per-node=192
#SBATCH --output=%x.o%j
##SBATCH --time=4:00:00
#SBATCH --time=0:30:00

set -eux
echo -n " $( date +%s )," >  job_timestamp.txt

set +x
MACHINE_ID=gaeac6
source ./module-setup.sh
module use --prepend $PWD/modulefiles
module load modules.fv3
module list
set -x

echo "Model started:  " `date`

export OMP_NUM_THREADS=1
export OMP_STACKSIZE=1024M
export NC_BLKSZ=1M
export ESMF_RUNTIME_PROFILE=ON
export ESMF_RUNTIME_PROFILE_OUTPUT="SUMMARY"
export FI_VERBS_PREFER_XRC=0
export FI_CXI_RX_MATCH_MODE=hybrid
export COMEX_EAGER_THRESHOLD=65536
export FI_CXI_RDZV_THRESHOLD=65536

# Avoid job errors because of filesystem synchronization delays
sync && sleep 1

# This "if" block is part of the rt.sh self-tests in error-test.conf. It emulates the model failing to run.
if [ "${JOB_SHOULD_FAIL:-NO}" = WHEN_RUNNING ] ; then
    echo "The job should abort now, with exit status 1." 1>&2
    echo "If error checking is working, the metascheduler should mark the job as failed." 1>&2
    false
fi

DEXE=/gpfs/f6/sfs-emc/scratch/Dmitry.Dukhovskoy/CODE/ufs-weather-model/tests
HEXE=fv3_s2s_32bit_sfs_intel.exe
#cp ${DEXE}/${HEXE} fv3.exe

srun --label -n 940 ./fv3.exe

echo "Model ended:    " `date`
echo -n " $( date +%s )," >> job_timestamp.txt

DLOG=logs.j${SLURM_JOB_ID}
mkdir -pv $DLOG
for file in log.atm* mediator.log logfile.* ${SLURM_JOB_NAME}.o* err
do
  mv $file ${DLOG}/.
done

for fl in input.nml model_configure ufs.configure
do
  cp $fl ${DLOG}/.
done



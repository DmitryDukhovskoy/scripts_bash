#!/bin/bash
#SBATCH -e err
#SBATCH -o out
#SBATCH --account=cefi
#SBATCH --qos=normal
##SBATCH --qos=debug
#SBATCH --partition=batch
#SBATCH --clusters=c5
#SBATCH --nodes=16
##SBATCH --ntasks-per-node=32
#SBATCH --time=6:00:00
##SBATCH --time=00:30:00
#SBATCH --output=%x.o%j
#SBATCH --job-name=SIS_sponge
#SBATCH --export=NONE
## 
## Usage: sbatch sub_mom6sis.sh
#set -eux
#set -v
set -ux
echo "Model started:  " `date`

#echo -n " $( date +%s )," >  job_timestamp.txt
echo -n " $( date +%Y%m%d-%H:%M:%S )," >  job_timestamp.txt

set +x
source $MODULESHOME/init/bash
##source /opt/cray/pe/lmod/lmod/init/bash
##module unload darshan-runtime
module unload cray-libsci
module unload cray-netcdf cray-hdf5 fre
module load PrgEnv-intel/8.5.0
module load libfabric/1.20.1
module unload intel
module load cray-hdf5/1.12.2.11
module load intel-classic/2023.2.0
module load fre/bronx-22
module load libyaml/0.2.5
module list 

export FI_VERBS_PREFER_XRC=0
#export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily/FMS2_MOM6_SIS2_compile_irlx/ncrc5.intel23-repro/exec
#export HEXE=fms_FMS2_MOM6_SIS2_compile_irlx.x
# Experiment with older ice relaxa versions, test point is hard-coded:
#export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily/FMS2_MOM6_SIS2_compile_irlxtest/ncrc5.intel23-repro/exec
#export HEXE=fms_FMS2_MOM6_SIS2_compile_irlxtest.x
# Source code used in BGC spinup:
#export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/volatile/fre/NEP/hindcast_bgc/NEPbgc_nudged_spinup/ptmp/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/FMS2_MOM6_SIS2_BGC_compile_irlx/ncrc5.intel23-repro/exec
#export HEXE=fms_FMS2_MOM6_SIS2_BGC_compile_irlx.x
# Latest version with ij-test:
#export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/FMS2_MOM6_SIS2_BGC_compile_irlx/ncrc5.intel23-repro/exec
#export HEXE=fms_FMS2_MOM6_SIS2_BGC_compile_irlx_ijtest.x
# Latest code with no ij-test option:
export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/FMS2_MOM6_SIS2_BGC_compile_irlx/ncrc5.intel23-repro/exec
export HEXE=fms_FMS2_MOM6_SIS2_BGC_compile_irlx.x

/bin/rm -f $HEXE
/bin/cp $DEXE/$HEXE .
# Avoid job errors because of filesystem synchronization delays
#sync && sleep 1

/usr/bin/srun --ntasks=2036 --cpus-per-task=1 --export=ALL ./${HEXE}

echo "Model ended:    " `date`
echo -n " $( date +%s )," >> job_timestamp.txt


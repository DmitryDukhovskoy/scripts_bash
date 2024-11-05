#!/bin/bash
#SBATCH -e err
#SBATCH -o out
#SBATCH --account=cefi
### #SBATCH --ntasks=240
##SBATCH --qos=normal
#SBATCH --qos=debug
#SBATCH --partition=batch
#SBATCH --clusters=c5
#SBATCH --nodes=16
##SBATCH --ntasks-per-node=32
##SBATCH --time=4:00:00
#SBATCH --time=00:30:00
#SBATCH --output=%x.o%j
#SBATCH --job-name=SIS_sponge
#SBATCH --export=NONE
## 
## Usage: sbatch sub_mom6sis.sh
#set -eux
#set -v
set -ux

#echo -n " $( date +%s )," >  job_timestamp.txt
echo -n " $( date +%Y%m%d-%H:%M:%S )," >  job_timestamp.txt

set +x
module unload darshan-runtime
module unload cray-libsci
module unload cray-netcdf cray-hdf5 fre
module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu PrgEnv-cray
module load PrgEnv-intel/8.5.0
module unload intel intel-classic intel-oneapi
module load cray-hdf5-parallel/1.14.3.1
module load intel-classic/2023.2.0
module load fre/bronx-22
module load cray-hdf5/1.12.2.11
module load libyaml/0.2.5
module list

echo "Model started:  " `date`

export FI_VERBS_PREFER_XRC=0
#export HEXE=fms_MOM6_SIS2_GENERIC_4P_compile_symm.x
#export HEXE=fms_FMS2_MOM6_SIS2_compile_symm.x
#export HEXE=MOM6SIS2
#export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/src/mom6/builds/build/gaea-ncrc5.intel23/ocean_ice/repro
export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily/FMS2_MOM6_SIS2_compile_symm/ncrc5.intel23-repro/exec
export HEXE=fms_FMS2_MOM6_SIS2_compile_symm.x
#export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_ensembles/FMS2_MOM6_SIS2_compile_symm/ncrc5.intel22-repro/exec
#export HEXE=isponge_FMS2_MOM6_SIS2.x

/bin/rm -f $HEXE
/bin/cp $DEXE/$HEXE .
# Avoid job errors because of filesystem synchronization delays
#sync && sleep 1

/usr/bin/srun --ntasks=2036 --cpus-per-task=1 --export=ALL ./${HEXE}

echo "Model ended:    " `date`
echo -n " $( date +%s )," >> job_timestamp.txt


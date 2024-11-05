#!/bin/bash
#SBATCH -e err
#SBATCH -o out
#SBATCH --account=cefi
### #SBATCH --ntasks=240
#SBATCH --qos=normal
##SBATCH --qos=debug
#SBATCH --partition=batch
#SBATCH --clusters=c5
#SBATCH --nodes=16
##SBATCH --ntasks-per-node=32
#SBATCH --time=4:00:00
##SBATCH --time=00:30:00
#SBATCH --output=%x.o%j
#SBATCH --job-name=NEP_seastest
#SBATCH --export=NONE
## 
## Usage: sbatch sub_mom6sis.sh
set -eux
#echo -n " $( date +%s )," >  job_timestamp.txt
echo -n " $( date +%Y%m%d-%H:%M:%S )," >  job_timestamp.txt

set +x
#module unload cray-netcdf cray-hdf5 fre
#module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu PrgEnv-cray
module load PrgEnv-intel/8.3.3
module unload intel intel-classic intel-oneapi
module load intel-classic/2022.0.2
module load cray-hdf5/1.12.2.3
module load libyaml/0.2.5
module load cray-netcdf/4.9.0.3


echo "Model started:  " `date`

#export HEXE=fms_MOM6_SIS2_GENERIC_4P_compile_symm.x
export HEXE=fms_FMS2_MOM6_SIS2_compile_symm.x
# Avoid job errors because of filesystem synchronization delays
#sync && sleep 1

/usr/bin/srun --ntasks=2036 --cpus-per-task=1 --export=ALL ./${HEXE}

echo "Model ended:    " `date`
echo -n " $( date +%s )," >> job_timestamp.txt


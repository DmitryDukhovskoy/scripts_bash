#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J HYCOM_archv
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=02:00:00
## 
# Get GEFS output for specified year & months
# check hpss example:
# hsi -P ls -l /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/
# untar from HPSS hycom archive n-24, ..., f36, ...  fields
# To see listing:
# htar -tvf /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/rtofs_archv_1_inc.tar
#
# with incrementally updated NCODA increments (from incup fields during 6hr update)
set -u

export YR1=2001


export DGEFS=/NCEPDEV/marineda/5year/DATM_INPUT/GEFS_new
export DUMP=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/GEFS_forcing

mkdir -pv $DUMP
cd ${DUMP}

for imo in {1..2}; do
  mo=`echo $imo | awk '{printf("%02d", $1)}'`
  FL=gefs.${YR1}${mo}.tar
  echo "untarring ${FL}"
  htar -xvf ${DGEFS}/${YR1}${mo}/${FL}
  wait
done

echo "Done "
pwd

exit 0



#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J MOMCICE_restart
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=03:00:00
#
# Transfer archive restart files from HPSS
# mom6 restarts, cice, datm.r 
#
# check expt before restart transfer!
#
# usage: ./bring_restart.sh YYYY MM DD 
#  
set -u

export expt=003
export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6_${expt}
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6/expt_${expt}
export SRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export ATMF=CFSR
export DRST=$DRUN/RESTART

if [[ $# == 3 ]] || [[ $# == 4 ]]; then
  YY=$1
  MM=$2
  DD=$3
  [[ $# == 4 ]] && HH=$4 || HH=0

  MM=`echo $MM | awk '{printf("%02d",$1)}'`
  DD=`echo $DD | awk '{printf("%02d",$1)}'`
  HH=`echo $HH | awk '{printf("%02d",$1)}'`
  printf "Archiving restarts for restart Date: $YY/$MM/$DD:$HH\n"
else
  echo "YY MM DD HH not provided: "
  echo "Usage: sbatch bring_restart.sh YYYY MM DD HH"
  exit 1
fi

if [ ! -d $DRST ]; then
  /bin/mkdir -pv $DRST
fi

echo "Fetching restart files from HPSS ----> $DRST"
cd $DRST
pwd

# Check if tar files exist:
FTAR=restarts_${YY}-${MM}-${DD}-${HH}
htar -tvf $HOUT/${FTAR}.tar
tar_success=$(htar -tvf $HOUT/${FTAR}.tar | grep -c 'HTAR SUCCESSFUL')

if [[ $tar_success == 0 ]] ; then
  echo "!!! ERROR READING $FTAR on HPSS2!!!"
  exit 1
fi

htar -xvf $HOUT/${FTAR}.tar
wait

ls -l *${YY}-${MM}-${DD}*.nc
/bin/mv DATM_*.datm.r.${YY}-${MM}-${DD}-00000.nc $DRUN/.

echo "All Done"

exit 0



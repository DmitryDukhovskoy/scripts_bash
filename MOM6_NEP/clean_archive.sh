#!/bin/sh 
# 
# Clean output archive and restart tar files
# After they have been transferred to PPAN / archive
set -u

PLTF=ncrc5.intel22-repro
RUN=NEPphys_frcst_climOB
DROOT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_ensembles

if [[ $# < 1 ]]; then
  echo "usage: ./clean_archive.sh YR1 [YR2 ]"
  echo " Start/end years are missing"
  exit 1
fi

YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi

cd $DROOT
pwd

yr=$YR1
while [ $yr -le $YR2 ]; do
  for rundir in $( ls -d ${RUN}_${yr}* ); do
    cd $DROOT/$rundir/$PLTF/archive
    echo "Deleting ascii, history, restart $rundir"
    /bin/rm -rf ascii/*.tar
    /bin/rm -rf history/*.tar
    /bin/rm -rf restart/*.tar
  done
  yr=$(( yr + 1 ))
done


exit 0


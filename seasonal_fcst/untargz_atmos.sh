#!/bin/bash
#
# Untar atmospheric SPEAR subset fields 
# prepared on PPANLS
# usage: ./untar_atmos.sh YR1 [YR2 ]
#
# For unzipping/untarring all atmos and ocean input fields use:
# unzip_input_dailyOB.sh
#
set -u

export WD=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy
export DATM=$WD/NEP_data/forecast_input_data/atmos

if [[ $# < 1 ]]; then
  echo "usage: ./untar_atmos.sh YR1 [YR2 ]"
  echo " Start/end years are missing"
  exit 1
fi

YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi

cd $DATM
pwd

yr=$YR1
while [ $yr -le $YR2 ]; do
  ls -l *${yr}*.tar.gz
  for ftar in $( ls *${yr}*.tar.gz ); do
    echo "Untarring $ftar"
    tar -xzvf $ftar

    status=$?
    if [[ $status == 0 ]]; then
      echo "Removing $ftar"
      /bin/rm $ftar
    fi
  done
  yr=$((yr + 1))
  echo "yr=$yr"

done

exit 0

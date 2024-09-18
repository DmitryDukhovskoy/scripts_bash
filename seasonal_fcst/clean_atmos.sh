#!/bin/bash -x
#
# Remove directories with SPEAR ensemble atmospheric fields 
# if the tar files have been icreated and sent to gaea
#
#
set -u

export DATM=/home/Dmitry.Dukhovskoy/work1/NEP_input/fcst_forcing/atmos
export DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos


YR1=$1
if [[ $# == 1 ]]; then
  YR2=$YR1
else
  YR2=$2
fi 

cd $DATM
pwd
ls -l *_sent

for fls in $( ls spear_atmos*_sent ); do
  dstmp=$(echo $fls | cut -d "_" -f3)
  YR=${dstmp:0:4}
  mo0=${dstmp:4:2}

  for drs in $(ls -d1 ${YR}-${mo0}-e??); do
    echo "Removing $drs"
    /bin/rm -rf $drs
  done
done

exit 0



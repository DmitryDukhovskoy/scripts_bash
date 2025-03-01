#!/bin/bash
#
# Clean output fields from old runs
# usage: ./clean_output.sh YR [MM] [ens1] [ens2] 
# 
set -u

export OUTDIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily
export EXPT=NEPphys_frcst_dailyOB
export expt_nmb=02
#export expt_nmb=""

if [[ $# -lt 1 ]]; then
  echo "usage: ./clean_output.sh YR [MM] [ens1] [ens2]"
  echo " Start year is missing"
  exit 1
fi
export expt_name=${EXPT}${expt_nmb}
YR=$1
flprfx=${expt_name}_${YR}-

if [[ $# -eq 2 ]]; then
  mo=$2
  MM=$( echo $mo | awk '{printf("%02d"), $1}' )
  flprfx=${flprfx}${MM}
fi

ens1=1
ens2=10
if [[ $# -eq 3 ]]; then
  ens1=$3
fi
if [[ $# -eq 4 ]]; then
  ens2=$4
fi

cd $OUTDIR
pwd
aa=$( du -h --max-depth=1 . | tail -1 )
nsize=$( echo $aa | cut -d' ' -f1 )
echo "Occupied storage ${nsize}"
date

for (( ens=$ens1; ens<=$ens2; ens+=1 )); do 
  ens0=$( echo $ens | awk '{printf("%02d"), $1}' )
  for drnm in $( ls -d ${flprfx}*e${ens0} ); do
    echo "Removing   ${drnm}  "
   /bin/rm -rf ${drnm}
  done
done

aa=$( du -h --max-depth=1 . | tail -1 )
nsize=$( echo $aa | cut -d' ' -f1 )
echo "After cleaning, occupied storage ${nsize}"
date

  
echo "       "
echo " All Done "

exit 0 


#!/bin/bash
#
# Remove not needed xml scripts
# usage: ./clean_output.sh YR1 [YR2] 
#
set -u

export OUTDIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst_dailyOB
export EXPT=NEPphys_seasfcst_dailyOB
export expt_nmb=02
#export expt_nmb=""

if [[ $# -lt 1 ]]; then
  echo "usage: ./clean_output.sh YR1 [YR2]"
  echo " Start year is missing"
  exit 1
fi
YR1=$1
YR2=$YR1

if [[ $# -eq 2 ]]; then
  YR2=$2
fi

cd $OUTDIR
pwd
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do 
  for fls in $( ls ${EXPT}_${yr}_??_e??.xml ); do
    echo "Removing   ${fls}  "
   /bin/rm -rf ${fls}
  done
done

exit 0 


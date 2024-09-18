#!/bin/bash -x
#SBATCH -e tar%j.err
#SBATCH -o tar%j.out
#SBATCH --account=cefi
#SBATCH --clusters=es
#SBATCH --partition=rdtn_c5
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --export=NONE
#
# transfer MOM6 output to PP/ANLS
# https://gaeadocs.rdhpcs.noaa.gov/wiki/index.php?title=Data_transfers
#
#
# Usage: ./gcp_mom2ppanls.sh - move all {prfx}_*
#     OR ./gcp_mom2ppanls.sh YYYY move {prfx}_YYYY*
#     OR Year and Month: ./gcp_mom2ppanls.sh YYYY MM  ---> move {prfx}_YYYYMM
#
set -u

module load gcp 

export expt=xxx
export DRUN=/gpfs/f5/cefi/scratch/${USER}/work/${expt}
export SRC=/ncrc/home1/${USER}/scripts/MOM6_NEP
export prfx=oceanm

export YR=1993
if [[ $# == 1 ]]; then
  YR=$1
fi

export MMT=0
if [[ $# == 2 ]]; then
  MMT=$2
fi
  
#export HOUT=/work/${USER}/run_output/${expt}/${YR}
export HOUT=xxx/xxx

cd $DRUN
for fdir in $(ls -d ${prfx}_[12]???[01]?)
do
  dmm=`echo $fdir | cut -d "_" -f2`
  YRD=`echo ${dmm:0:4}`
  MMD=`echo ${dmm:4:6}`
# Clearly specify decimals for correct interpretation of
# the numbers with leading 0's, 08 = 8, otherwise
# it will be interpreted as octal number
  if (( 10#$YR > 0 )) && (( 10#$YRD != 10#$YR )); then
    continue
  fi

  if (( 10#$MMT > 0 )) && (( 10#$MMD != 10#$MMT )); then
    echo "Skipping month $MMD"
    continue
  fi

  cd ${DRUN}/${fdir}
  for tarf in $(ls ${prfx}_${YR}${MMD}*.tar.gz); do
# First check if files have been  sent to remote storage
    fbsnm=`echo $tarf | cut -d "." -f1`
    chck_file=${fbsnm}_sent
    if [[ -f $chck_file ]]; then
      echo "Output from $fdir has been sent to remote archive, skipping ..."
      continue
    fi

    echo "Sending $YRD $MMD:  $tarf  "
    gcp -cd ${tarf} gfdl:${HOUT}/${MMD}/
    wait

    `echo $tarf > $chck_file`

  done
  cd $DRUN
done

exit 0


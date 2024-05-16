#!/bin/bash -x
##SBATCH --nodes=1 --tasks-per-node=1
##SBATCH -J HYCOM_archv
##SBATCH -A marine-cpu
##SBATCH --partition=service 
##SBATCH -q debug
##SBATCH --time=06:00:00
#
# transfer MOM6 output to PP/ANLS
# https://gaeadocs.rdhpcs.noaa.gov/wiki/index.php?title=Data_transfers
#
#
# Usage: ./gcp_mom2ppanls.sh - move all tarmom_*
#     OR ./gcp_mom2ppanls.sh YYYY move tarmom_YYYY*
#     OR Year and Month: ./gcp_mom2ppanls.sh YYYY MM  ---> move tarmom_YYYYMM
#
set -u

module load gcp 

export YR=1993
export expt='NEP_BGCphys'
export DRUN=/gpfs/f5/cefi/scratch/${USER}/work/${expt}
export HOUT=/work/${USER}/run_output/${expt}/${YR}
export SRC=/ncrc/home1/${USER}/scripts/MOM6_NEP

if [[ $# == 1 ]]; then
  YR=$1
fi

MMT=0
if [[ $# == 2 ]]; then
  MMT=$2
fi

export Nft=11     # # of output files in 1 tar file
export fnm=ocean
export chck_file=gcp2ppanls_completed

cd $DRUN
for fdir in $(ls -d tarmom_${YR}??)
do
  cd $DRUN 
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

  cd $fdir
# First check if files have been  sent to remote storage
  if [[ -f $chck_file ]]; then
    echo "Output from $fdir has been sent to remote archive, skipping ..."
    cd $DRUN
    continue
  fi
  nfls=`ls -l ${fnm}_${YRD}*nc 2>/dev/null | wc -l`
  if (( $nfls == 0 )); then
    echo "$fdir no MOM output found"
    continue
  fi

  echo "Sending $YRD $MMD:  $nfls output files "
  for flmom in $(ls -1 ${fnm}_${YRD}_???_??.nc)
  do 
    gcp -cd ${flmom} gfdl:${HOUT}/${MMD}/
  done
  cd $DRUN
done


exit 0


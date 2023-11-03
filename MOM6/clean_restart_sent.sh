#!/bin/bash 
#
# clean RESTART dir 
# remove restart files that have been sent to HPSS
# using flchck file
#
# NOAA/NWS/EMC Dmitry Dukhovskoy  2023
#
set -u 

export expt=003
export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6_${expt}
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6/expt_${expt}
export SRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export ATMF=CFSR
export SENT=${DRUN}/RESTART/SENT
export DUMP=$DRUN/RESTART/DUMP

cd $SENT
pwd
du -h --max-depth=1

sfx=sent2hpss
for fll in $( ls -1 *${sfx} ); do
  rfile=`echo $fll | cut -d '_' -f1`
  fend=$(echo ${fll} | cut -d '.' -f1)
#  dstmp=$(echo ${fend} | tr -cd '[[:digit:]]')
  

  if [[ $rfile == "cice6restart" ]]; then
    dstmp=$(echo ${fend} | cut -d '_' -f2)
    prefx='iced.'
  elif [[ $rfile == "mom6restart" ]]; then
    dstmp=$(echo ${fend} | cut -d '_' -f2)
    prefx='MOM.res.'
  elif [[ $rfile == "DATM" ]]; then
    dstmp=$(echo ${fend} | cut -d '_' -f3)
    prefx='DATM_'
  fi
    
  YY=$(echo $dstmp | cut -d '-' -f1)
  MM=$(echo $dstmp | cut -d '-' -f2)
  DD=$(echo $dstmp | cut -d '-' -f3)

  echo "Removing restart: ${prefx}*${YY}*${MM}*${DD}*.nc"
  /bin/rm ${DUMP}/${prefx}*${YY}*${MM}*${DD}*.nc
done

du -h --max-depth=1

exit 0


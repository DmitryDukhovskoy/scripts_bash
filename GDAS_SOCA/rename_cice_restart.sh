#! /bin/sh -x
#
# Rename CICE restart from:
# iced.2021-07-02-21600.nc ---> 20210701.060000.cice_model.res.nc
# 
# hours are derived from the file name (last 5 digits = seconds)
#
# Usage: ./rename_cice_restart.sh YYYY MM DD 
#
set -u

export RD=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/GDAS/ICSDIR/C384O008
export sfx=00
export bname="cice_model.res"

export HH=XXXX
if [[ $# == 3 ]]; then
  export YY=$1
  export MM=$2
  export DD=$3
else
  printf "Usage ./rename_cice_restart.sh YYYY MM DD "
  exit 1
fi

cd $RD

for fhr in 00 06 12 18
do
  export IDR=$RD/gdas.${YY}${MM}${DD}/$fhr/ice/RESTART
  cd $IDR
# Saved from the previous cycle
  nrst=`ls -1 iced.????-??-??-?????.nc 2>/dev/null | wc -l`
  if [[ $nrst == 0 ]]; then
    echo " "
    echo "Check: Missing restart $IDR/iced.*.nc"
    echo " Exiting ..."
    exit 1
  fi

# Should be 1 file but just in case check for several files
# File are +6hr of the analysis date, so get the date/time stamp from the file name
  for FL in $(ls iced.????-??-??-?????.nc)
  do
    fdate=$(echo $FL | cut -d "." -f 2)
    YYf=$(echo $fdate | cut -d "-" -f 1)
    MMf=$(echo $fdate | cut -d "-" -f 2)
    DDf=$(echo $fdate | cut -d "-" -f 3)
    nsec=$(echo $fdate | cut -d "-" -f 4)
    HH=$(( 10#${nsec}/3600 ))
    HH=$( echo $HH | awk '{printf("%02d", $1)}' )
    FLnew=${YYf}${MMf}${DDf}.${HH}0000.${bname}.nc
    echo "$FL ---> ${FLnew}"
    /bin/mv $FL $FLnew 
  done

  pwd
  ls -l *.nc

done

exit 0



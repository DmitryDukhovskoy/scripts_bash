#! /bin/sh -x
#
# Rename MOM restart from:
# MOM.res.2021-07-02-00-00*.nc ---> 20210701.060000.MOM.res*.nc
# Note that MOM dumps restarts saved as:
# YYYYMMDD.?????.MOM.res_*.nc where ????? is # of seconds
# First, Use arrange_mom_restart.sh to rename 
# YYYYMMDD.?????.MOM.res_*.nc ---> MOM.res.2021-07-02-00-00*.nc
# 
# Or directly this script if the restarts have been renamed
#
set -u

export RD=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/GDAS/ICSDIR/C384O008
export sfx=00
export bname="MOM.res"

if [[ $# == 4 ]]; then
  export YY=$1
  export MM=$2
  export DD=$3
  export HH=$4
elif [[ $# == 3 ]]; then
  export YY=$1
  export MM=$2
  export DD=$3
  export HH=00
else
  printf "Usage ./rename_ocean_restart.sh YYYY MM DD HH or \n"
  exit 1
fi

cd $RD

# Need to have MOM.res.YYYY-MM-DD-hr-00*.nc in RESTART
# Saved from the previous cycle
nrst=`ls -1 ${bname}.${YY}-${MM}-${DD}-${HH}-*.nc 2>/dev/null | wc -l`
if [[ $nrst == 0 ]]; then
  echo " "
  echo "Check: Missing restart $RD/${bname}.${YY}-${MM}-${DD}-${HH}-*.nc"
  echo " Exiting ..."
  exit 1
fi

# First files with *_[1, ...].nc
for FL in $(ls ${bname}.${YY}-${MM}-${DD}-${HH}-*_*.nc)
do
  fdate=$(echo $FL | cut -d "." -f 3)
  sfx=$( echo $fdate | cut -d "_" -f 2)
  FLnew=${YY}${MM}${DD}.${HH}0000.${bname}_${sfx}.nc
  echo "$FL ---> ${FLnew}"
  /bin/mv $FL $FLnew 
done

for FL in $(ls ${bname}.${YY}-${MM}-${DD}-${HH}-??.nc)
do
  FLnew=${YY}${MM}${DD}.${HH}0000.${bname}.nc
  echo "$FL ---> ${FLnew}"
  /bin/mv $FL $FLnew
done

pwd
ls -l ${YY}${MM}${DD}.*.nc
exit 0



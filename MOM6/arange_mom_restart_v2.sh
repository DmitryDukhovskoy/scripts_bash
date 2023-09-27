#! /bin/sh -x
# Rename restart files 
# Saved in a modified format with date stamp in the name
# rename into a different name format: 
# from YYYYMMDD.?????.MOM.res_*.nc -----> MOM.res.YYYY-MM-DD-HH-00_[1-...].nc 
#
# Restart date for dumped MOM restart files:
# usage arange_mom_restart.sh YYYY MM DD HH
#     OR arange_mom_restart.sh CYC[1,..., N cycles]
# 
#
set -u

echo " Preparing MOM restart for next cycle "

export WD=`pwd`
export RD=${WD}/RESTART
export DINP=${WD}/INPUT

export sfx=00
export bname="MOM.res"

if [[ $# == 4 ]]; then
  export YY=$1
  export MM=$2
  export DD=$3
  export HH=$4
elif [[ $# == 1 ]]; then
  export ncycle=$1

  dStart=`grep "cycle[ ]*${ncycle}" list_cycles.txt | cut -d ":" -f2`

  YY=`echo $dStart | cut -d ' ' -f1`
  MM=`echo $dStart | cut -d ' ' -f2`
  DD=`echo $dStart | cut -d ' ' -f3`
  HH=`echo $dStart | cut -d ' ' -f4`

else
  printf "Usage ./rename_restart.sh YY MM DD HH or \n"
  printf "   specify date of the restart file\n"
  printf "   or specify cycle number that this restart belongs"
  printf "   check $RD/list_cycles.txt "
  exit 1
fi

export dstmp=${YY}-${MM}-${DD}-${HH}-${sfx}
printf "Restart date: $YY/$MM/$DD:$HH\n"

cd $RD
# Need to have YYYYMMDD.*.MOM.res_*.nc in RESTART
# Saved from the previous cycle
nrst=`ls -1 ${YY}${MM}${DD}.*.${bname}_*.nc 2>/dev/null | wc -l`
if [[ $nrst == 0 ]]; then
  echo " "
  echo "Check: Missing restart $RD/${bname}_*.nc from the last cycle"
  echo " Looking for ${YY}${MM}${DD}.*.${bname}_*.nc"
  echo "${YY}${MM}${DD}.MOM.res_ ---> MOM.res.${YY}-${MM}-${DD} ... cannot be performed"
  echo " Exiting ..."
  exit 1
fi

for FL in $(ls ${YY}${MM}${DD}.*.${bname}_*.nc)
do
#  fl1=$(echo $FL | cut -d "_" -f 1)
# Check hours:
  nsec=$(echo $FL | cut -d "." -f 2)
  nhrs=$(( 10#${nsec}/3600 ))

  if [[ $(( 10#$nhrs - 10#$HH )) > 0 ]]; then
    echo " ERR: MOM restart: time stamp hours ${nhrs}, expected ${HH}"
    echo " Check restart time, exiting ..."
    exit 2
  fi

  fl2=$(echo $FL | cut -d "_" -f 2)  
  export flnew="${bname}.${dstmp}_${fl2}"

# Do not overide existing restart for this date
  if [[ -f $flnew ]]; then
    printf "Restart file exist $RD/$flnew \n"
    printf " Check restart date or clean RESTART"
    exit 1 
  fi

  printf " Moving $FL ---> $flnew \n"
  /bin/mv ${FL} ${flnew}
done

for FL in $(ls ${YY}${MM}${DD}.*.${bname}.nc)
do 
  export flnew="${bname}.${dstmp}.nc"
  printf " Moving $FL ---> $flnew \n"
  /bin/mv ${FL} ${flnew}
done

echo "Arranging MOM restart: All Done"

cd $WD

exit 0


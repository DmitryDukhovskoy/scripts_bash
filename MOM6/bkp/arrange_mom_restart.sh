#! /bin/sh -x
# Rename restart files 
# from MOM.res_*.nc -----> MOM.res.YYYY-MM-DD-HH-00_[1-...].nc 
#
# Restart date for dumped MOM restart files:
# usage arrange_mom_restart.sh YYYY MM DD HH
#     OR arrange_mom_restart.sh CYC[1,..., N cycles]
# 
#
set -u

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

  dStart=`grep "cycle[ ]*${ncycle} " list_cycles.txt | cut -d ":" -f2`

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
# Need to have MOM6.res_*.nc - assumed the latest restart!
nrst=`ls -1 ${bname}_*.nc 2>/dev/null | wc -l`
if [[ $nrst == 0 ]]; then
  echo "ERROR: Missing restart $RD/${bname}_*.nc"
  exit 1
fi

for FL in $(ls ${bname}_*.nc)
do
#  fl1=$(echo $FL | cut -d "_" -f 1)
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

export FL=${bname}.nc
export flnew="${bname}.${dstmp}.nc"
printf " Moving $FL ---> $flnew \n"
/bin/mv ${FL} ${flnew}

echo "All Done"

cd $WD

exit 0


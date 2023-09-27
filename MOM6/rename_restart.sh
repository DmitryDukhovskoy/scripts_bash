#! /bin/sh -x
# Rename restart files 
# from MOM.res.YYYY-MM-DD-HH-00_[1-...].nc ---> MOM.res_[1-...].nc 
#      MOM.res.YYYY-MM-DD-HH-00.nc  ----> MOM.res.nc 
#
# usage rename_restart.sh 2005 01 06 12 [YY MM DD HH]
# or modify dstmp 
#
set -u

export WD=`pwd`
export RD=${WD}/RESTART
export DINP=${WD}/INPUT

export dstmp=2020-01-01-00
export sfx=00
export bname="MOM.res"

if [[ $# == 4 ]]; then
  export YY=$1
  export MM=$2
  export DD=$3
  export HH=$4
  export dstmp=2020-01-01-00
else
  printf "Usage ./rename_restart.sh YY MM DD HH or \n"
  printf "   specify in the script dstmp then ./rename_restart.sh\n"
  printf "Restart date not provided use $dstmp\n"
fi

cd $RD
# Need to have MOM6.res.YYYY-MM-DD-HH-00.nc files
nrst=`ls -1 ${bname}.${dstmp}*nc 2>/dev/null | wc -l`
if [[ $nrst == 0 ]]; then
  echo "ERROR: Missing restart $RD/${bname}.${dstmp}*nc"
  exit 1
fi

for FL in $(ls ${bname}.${dstmp}-${sfx}_*.nc)
do
#  fl1=$(echo $FL | cut -d "_" -f 1)
  fl2=$(echo $FL | cut -d "_" -f 2)  
  export flnew="${bname}_${fl2}"
  printf " Moving $FL ---> $flnew \n"
  /bin/ln ${FL} ${flnew}
done

export FL=${bname}.${dstmp}-${sfx}.nc
export flnew="${bname}.nc"
printf " Moving $FL ---> $flnew \n"
/bin/ln ${FL} ${flnew}

cd ${DINP}
printf " Moving restart to ${DINP}/"
#/bin/ln -sf ../RESTART/${bname}_*.nc .
#/bin/ln -sf ../RESTART/${bname}.nc .
/bin/mv ${RD}/${bname}_*.nc .
/bin/mv ${RD}/${bname}.nc .


nrst=`ls -1 ${bname}*nc 2>/dev/null | wc -l`
echo "Found $nrst RESTART files in ${DINP}"

echo "All Done"

cd $WD

exit 0


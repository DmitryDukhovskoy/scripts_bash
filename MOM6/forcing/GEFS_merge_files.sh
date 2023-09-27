#!/bin/bash -x

export Y=2001
export Y2=2001
export DFORC=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/GEFS_forcing
cd $DFORC
pwd

rec=1
#for d in $(ls gefs.${Y}??????.nc gefs.${Y2}010100.nc)
for d in $(ls gefs.${Y}??????.nc)
do
  export f=`basename ${d} .nc`
  ncks --mk_rec_dmn time ${d} ${f}_${rec}.nc
  echo ${f}
  echo ${f}_${rec}
  rec=$(( rec+1 ))
done
ncrcat gefs.??????????_*.nc out.nc

exit 0

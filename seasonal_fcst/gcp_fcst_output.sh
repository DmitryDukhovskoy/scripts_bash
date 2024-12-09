#!/bin/bash
#
# Copy output fields to gaea 
# For cases when transfer was interrupted
#
# usage: ./gcp_fcst_output.sh YR MM [ens1] [ens2] 
#
set -u

export OUTDIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily
export EXPT=NEPphys_frcst_dailyOB
export PLTF=ncrc5.intel23-repro
export GPLTF=gfdl.${PLTF}
export expt_nmb=02
export RDIR=/archive/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily
#export expt_nmb=""

if [[ $# -lt 2 ]]; then
  echo "# usage: ./gcp_fcst_output.sh YR MM [ens1] [ens2]" 
  echo " Start year  and month are missing"
  exit 1
fi
export expt_name=${EXPT}${expt_nmb}
YR=$1
M1=$2
MM=$( echo $M1 | awk '{printf("%02d", $1)}' )
flprfx=${expt_name}_${YR}-${MM}

ens1=1
ens2=10
if [[ $# -eq 3 ]]; then
  ens1=$3
  ens2=$ens1
fi
if [[ $# -eq 4 ]]; then
  ens1=$3
  ens2=$4
fi

cd $OUTDIR/
pwd
date

for (( ens=$ens1; ens<=$ens2; ens+=1 )); do
  cd $OUTDIR 
  ens0=$( echo $ens | awk '{printf("%02d"), $1}' )
  for drnm in $( ls -d ${flprfx}*e${ens0} ); do
    echo "Processing  ${drnm}  "
    dir_arch=$OUTDIR/${drnm}/${PLTF}/archive
    if [ -d $dir_arch ]; then
      cd $OUTDIR/${drnm}/${PLTF}/archive
    else
      echo "output dir does not exist: $dir_arch "
      continue
    fi

    dir_ppan=$RDIR/$drnm/$GPLTF

    cd $OUTDIR/${drnm}/${PLTF}/archive/ascii
    pwd
    flnm=${YR}${MM}01.ascii_out.tar
    echo "gcp $flnm ---> gfdl: $dir_ppan/ascii"
    gcp -cd $flnm gfdl:$dir_ppan/ascii/.

    cd $OUTDIR/${drnm}/${PLTF}/archive/history
    pwd
    flnm=${YR}${MM}01.nc.tar
    echo "gcp $flnm ---> gfdl: $dir_ppan/history"
    gcp -cd $flnm gfdl:$dir_ppan/history/.

    cd $OUTDIR/${drnm}/${PLTF}/archive/restart
    pwd
    YRp1=$(( YR+=1 ))
    flnm=${YRp1}${MM}01.tar
    echo "gcp $flnm ---> gfdl: $dir_ppan/restart"
    gcp -cd $flnm gfdl:$dir_ppan/restart/.
    
  done
done

date

  
echo "       "
echo " All Done "

exit 0 


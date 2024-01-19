#!/bin/sh -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J GOFStransfer
#SBATCH -A fv3-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=06:00:00
#
# Get GOFS3.1 restart files
#
set -u

YR=2021
export DSAVE=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/GOFS3.1/restart
export DHPSS=/NCEPPROD/hpssprod/runhistory/rh${YR}

cd $DSAVE
pwd

MM1=11
#MM2=$(( MM1+1 ))
MM2=$MM1
DD1=1
DD2=28
dD=7
for (( MM = MM1; MM <= MM2; MM = MM+1 ))
do 
  for (( DD = DD1; DD <= DD2; DD = DD+dD ))
  do 
    YM=$(echo ${YR} ${MM} | awk '{printf("%04d%02d",$1, $2)}')
    YMD=$(echo ${YR} ${MM} ${DD} | awk '{printf("%04d%02d%02d",$1, $2, $3)}')
    DRIN=${DHPSS}/${YM}/${YMD}
    ftar=dcom_prod_${YMD}.tar

    echo "Retrieving ${DRIN}/${ftar} restart_r${YMD}00_930.[ab].gz"
    fll=restart_r${YMD}00_930

    if [[ -s ./wgrdbul/${fll}.a.gz && -s ./wgrdbul/${fll}.b.gz ]]; then
      echo "${fll}.[ab].gz exist"
    else
      htar -xvf ${DRIN}/${ftar} ./wgrdbul/${fll}.a.gz \
                              ./wgrdbul/${fll}.b.gz
      wait
    fi 
 
  done
done

for (( MM = MM1; MM <= MM2; MM = MM+1 ))
do
  YM=$(echo ${YR} ${MM} | awk '{printf("%04d%02d",$1, $2)}')
  /bin/mv ./wgrdbul/restart_r${YM}*.gz .
  for flgz in $(ls restart_r${YM}*.gz)
  do
    gunzip ${flgz}
    wait
  done
done

exit 0

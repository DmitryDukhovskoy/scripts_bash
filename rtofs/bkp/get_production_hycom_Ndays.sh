#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J PROD_archv
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=04:00:00
#
# check hpss example:
# hsi -P ls -l /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/
# untar from HPSS hycom archive n-24 fields
# To see listing:
# htar -tvf /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/rtofs_archv_1_inc.tar
#
# with incrementally updated NCODA increments (from incup fields during 6hr update)
set -u

#/NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.prod/rtofs.[YYYYMMDD]


export sfx=n-24
export DRUN=NCEPPROD
export D="/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/wcoss2.prod"

YR=2023
mo=05
for mday in {5..9}
do
  dday=`echo ${mday} | awk '{printf("%02d", $1)}'`
  export RD=${YR}${mo}${dday}
  export ryrmo=`echo $RD | cut -c 1-6`
  export DUMP="${D}/rtofs.$RD"
  export DHPSS=/${DRUN}/5year/hpssprod/runhistory/rh${YR}/${ryrmo}/${RD}
  export FL="rtofs_glo.t00z.${sfx}.archv"
  export FTAR="com_rtofs_v2.3_rtofs.${RD}.ab.tar"
  echo "rdate $RD"
  mkdir -pv $DUMP
  cd ${DUMP}

  echo "Check experiment file ${FL}"
  if [ -f ${FL}.a ] && [ -f ${FL}.b ]; then
    echo "${DUMP}/${FL}.[ab] exist, skipping ..."
    continue
  fi

# Forecasts, f000, f024, etc
# rtofs_glo_2ds_n016_ice.nc
#for fhr in 000 024 048 072 096 120 144 168 192; do
  htar -xvf ${DHPSS}/${FTAR} ./${FL}.a.tgz
  wait 
  tar -xzvf ${FL}.a.tgz
  wait

  htar -xvf ${DHPSS}/${FTAR} ./${FL}.b
  wait 

  /bin/rm ${FL}.a.tgz

  pwd
  ls -l
done

exit 0


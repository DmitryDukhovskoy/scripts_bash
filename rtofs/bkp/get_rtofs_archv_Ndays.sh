#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J HYCOM_archv
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=02:00:00
# 
# Get parallel run output fields for several days
# check hpss example:
# hsi -P ls -l /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/
# untar from HPSS hycom archive n-24, ..., f36, ...  fields
# To see listing:
# htar -tvf /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/rtofs_archv_1_inc.tar
#
# with incrementally updated NCODA increments (from incup fields during 6hr update)
set -u

#/NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.prod/rtofs.[YYYYMMDD]

#if [[ $#<2 ]]; then
#  printf " ERR: Usage get_rtofs_archv.sh YYYYMMDD [e.g., 20230123] n-24 [archive type]"
#  exit 1
#fi
sfx=n-24
export DRUN=NCEPDEV
export expt=paraD5
export D=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/${expt}

YR=2023
mo=05
for mday in {5..8}
do
  dday=`echo ${mday} | awk '{printf("%02d", $1)}'`
  export RD=${YR}${mo}${dday}
  export DUMP="${D}/rtofs.$RD"
  export FL="rtofs_glo.t00z.${sfx}.archv"
  echo "rdate $RD"
  mkdir -pv $DUMP
  cd ${DUMP}

  echo "Check experiment ${expt} and file ${FL}"
#htar -xvf /NCEPPROD/5year/hpssprod/runhistory/rh${RD:0:4}/${RD:0:6}/$RD/com_rtofs_prod_rtofs.$RD.ab.tar '*'n-24.archv.'*' '*'n00.archv.'*'
  htar -xvf /${DRUN}/emc-ocean/5year/Dan.Iredell/wcoss2.${expt}/rtofs.${RD}/rtofs.ab.tar ${FL}.a.tgz ${FL}.b

  wait 

  pwd
  ls -l

  tar -xzvf ${FL}.a.tgz
  wait

  if [ -f ${FL}.a ]; then
    /bin/rm ${FL}.a.tgz
  fi

  pwd
  ls -l
done

exit 0


#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J HYCOM_archv
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=00:30:00
# 
# Get parallel run output fields
# check hpss example:
# hsi -P ls -l /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/
# untar from HPSS hycom archive all files 
# To see listing:
# htar -tvf /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/rtofs_archv_1_inc.tar
#
# with incrementally updated NCODA increments (from incup fields during 6hr update)
set -u

#/NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.prod/rtofs.[YYYYMMDD]

if [[ $#<1 ]]; then
  printf " ERR: Usage get_rtofs_archv.sh YYYYMMDD [e.g., 20230123] "
  exit 1
fi
 
RD=$1
export DRUN=NCEPDEV
export expt=paraD1
export D=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/${expt}
export DUMP="${D}/rtofs.$RD"
#export FL="rtofs_glo.t00z.${sfx}.archv"
mkdir -pv $DUMP
cd ${DUMP}
#htar -xvf /NCEPPROD/5year/hpssprod/runhistory/rh${RD:0:4}/${RD:0:6}/$RD/com_rtofs_prod_rtofs.$RD.ab.tar ./'*'n-24.archv.'*' ./'*'n00.archv.'*'
htar -xvf /${DRUN}/emc-ocean/5year/Dan.Iredell/wcoss2.${expt}/rtofs.${RD}/rtofs.ab.tar 

wait 

pwd
ls -l

tar -xzvf *.a.tgz
wait

tar -xzvf *.b.tgz
wait

/bin/rm *.tgz

pwd
ls -l

exit 0


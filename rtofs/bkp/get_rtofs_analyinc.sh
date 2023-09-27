#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J analinc 
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=00:30:00
# 
# Get analysis increments *analinc* in layers 
#  geoptl_pre_1o4500x3298_2023040200_0000_analinc
# lyrprs_lyr_1o4500x3298_2023040200_0000_analinc
# salint_lyr_1o4500x3298_2023040200_0000_analinc
# seatmp_lyr_1o4500x3298_2023040200_0000_analinc
#
# Get parallel run output fields
# check hpss example:
# hsi -P ls -l /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/
# untar from HPSS hycom archive all files 
# To see listing:
# htar -tvf /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.20230118/rtofs_archv_1_inc.tar
#
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
export DUMP="${D}/rtofs.$RD/analinc"
mkdir -pv $DUMP
cd ${DUMP}

for fl in lyrprs salint seatmp uucurr vvcurr; do 
  htar -xvf /${DRUN}/emc-ocean/5year/Dan.Iredell/wcoss2.${expt}/rtofs.${RD}/rtofs.da.tar hycom_var/restart/${fl}_lyr'*'analinc
  wait 
done

htar -xvf /${DRUN}/emc-ocean/5year/Dan.Iredell/wcoss2.${expt}/rtofs.${RD}/rtofs.da.tar hycom_var/restart/icecov'*'analinc

/bin/mv hycom_var/restart/* ${DUMP}/.
/bin/rm -r hycom_var
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


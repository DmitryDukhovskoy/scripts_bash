#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J CICE_output
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=00:30:00
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

if [[ $#<2 ]]; then
  printf " ERR: Usage get_production_hycom.sh YYYYMMDD [e.g., 20230123] n-24 [archive type]"
  exit 1
fi

RD=$1
sfx=$2
rdate=$RD
ryrmo=`echo $RD | cut -c 1-6`
YR=`echo $RD | cut -c 1-4`

# in NCEPPROD/1year - netCdf and grb output
# NCEPPROD/5year - original *.[a,b] 
export DRUN=NCEPPROD
export DHPSS=/${DRUN}/5year/hpssprod/runhistory/rh${YR}/${ryrmo}/${RD}
export D="/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/wcoss2.prod"
export DUMP="${D}/rtofs.$RD"
#export FL=com_rtofs_v2.2_rtofs.${rdate}.nc.tar  # v2.2 changed to v2.3 in Aug 2022
#export FL=com_rtofs_v2.3_rtofs.${rdate}.nc.tar  # v2.2 changed to v2.3 in Aug 2022
export FL=com_rtofs_v2.3_rtofs.${RD}.ab.tar
mkdir -pv $DUMP
cd ${DUMP}
#htar -xvf /NCEPPROD/5year/hpssprod/runhistory/rh${RD:0:4}/${RD:0:6}/$RD/com_rtofs_prod_rtofs.$RD.ab.tar ./'*'n-24.archv.'*' ./'*'n00.archv.'*'

# Forecasts, f000, f024, etc
# rtofs_glo_2ds_n016_ice.nc
#for fhr in 000 024 048 072 096 120 144 168 192; do
htar -xvf ${DHPSS}/${FL} ./rtofs_glo.t00z.${sfx}.archv.a.tgz
wait 
tar -xzvf rtofs_glo.t00z.${sfx}.archv.a.tgz
wait

htar -xvf ${DHPSS}/${FL} ./rtofs_glo.t00z.${sfx}.archv.b
#done

/bin/rm rtofs_glo.t00z.${sfx}.archv.a.tgz

pwd
ls -l


exit 0


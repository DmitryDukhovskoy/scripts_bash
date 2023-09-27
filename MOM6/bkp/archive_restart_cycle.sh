#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J MOMCICE_restart
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=03:00:00
#
# archive restart files for cycle = CYC in the current run:
# mom6 restarts, cice, datm.r 
#
# the code uses list_cycles.txt to determine dates
#
# Usage:
# sbatch archive_restart_cycle.sh CYC=[1, ... ]
# OR 
# sbatch archive_restart_cycle.sh YY MM DD HH
#
# NOAA/NWS/EMC Dmitry Dukhovskoy  2023
#
set -u 

export expt=001
export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6/expt_${expt}
export SRC=/home/Dmitry.Dukhovskoy/scripts/MOM6

CYC=0
if [[ $# == 1 ]]; then
  CYC=$1
# Get rid of leading 0 in CYC if there is
  CYC=$(( 10#$CYC ))

  cd $DRUN

  # Restart date for current cycle:
  dStart=`grep "^cycle[ ]*${CYC}, " list_cycles.txt | cut -d ":" -f2`

  YY=`echo $dStart | cut -d ' ' -f1`
  MM=`echo $dStart | cut -d ' ' -f2`
  DD=`echo $dStart | cut -d ' ' -f3`
  HH=`echo $dStart | cut -d ' ' -f4`

  printf "Archiving restarts for cycle ${CYC} Start: $YY/$MM/$DD:$HH\n"
elif [[ $# == 4 ]]; then
  YY=$1
  MM=$2
  DD=$3
  HH=$4

  MM=`echo $MM | awk '{printf("%02d",$1)}'`
  DD=`echo $DD | awk '{printf("%02d",$1)}'`
  HH=`echo $HH | awk '{printf("%02d",$1)}'`
  printf "Archiving restarts for restart Date: $YY/$MM/$DD:$HH\n"
else
  echo "Cycle number or YY MM DD HH not provided: "
  echo "Usage: sbatch archive_restart_cycle.sh CYC=[1, ... ]"
  echo "Usage: sbatch archive_restart_cycle.sh YY MM DD HH"
  exit 1
fi


FDATM=DATM_GEFS.datm.r.${YY}-${MM}-${DD}-00000.nc
echo "Moving $FDATM to HPSS:$HOUT"
hsi put $DRUN/${FDATM} : $HOUT/${FDATM}
wait

# CICE restart:
first=iced
cd $DRUN/RESTART
pwd
ls -l ${first}.${YY}*.nc

nsec=$(( 10#$HH*3600 ))
nsec=`echo $nsec | awk '{printf("%05d",$1)}'`
flcice=${first}.${YY}-${MM}-${DD}-${nsec}.nc
flchck=cice6restart_${YY}-${MM}-${DD}-${nsec}.sent2hpss
if [[ ! -f $flcice ]]; then
  echo "CICE restart file not found ${flcice}"
#  exit 1
elif [[ -f $flchck ]]; then
  echo "CICE $flcice sent to HPSS, no action taken " 
else

  CTAR=cice_restart.${YY}-${MM}-${DD}-${nsec}.tar.gz
  echo "Tarring $CTAR"
  tar -cvzf ${CTAR} ${flcice}
  wait

  echo "Moving $CTAR to HPSS:$HOUT"
  hsi put ${CTAR} : $HOUT/${CTAR}
  wait

  ntar=`hsi -P ls -1 $HOUT | grep ${CTAR} | wc -l`
  echo $ntar
  if [[ $ntar == 0 ]]; then
    echo "!!! $CTAR not found on HPSS $HOUT !!!"
  else
    touch $flchck
  #
    echo "$CTAR is on HPSS, removing local $CTAR"
    /bin/rm -f $CTAR
  fi
fi


# MOM restart
cd $DRUN/RESTART
pwd
ls -l MOM.res.${YY}-${MM}*.nc
nrst=`ls -1 MOM.res.${YY}-${MM}-${DD}-${HH}*.nc 2>/dev/null | wc -l`
flchck=mom6restart_${YY}-${MM}-${DD}-${HH}.sent2hpss
if [[ $nrst == 0 ]]; then
  echo "MOM restart not found"
#  exit 1
elif [[ -f $flchck ]]; then
  echo "MOM.res.${YY}-${MM}*.nc sent to HPSS, no action taken"
else
  MTAR=mom_restart.${YY}-${MM}-${DD}-${HH}.tar.gz
  echo "Tarring $MTAR"
  tar -cvzf ${MTAR} MOM.res.${YY}-${MM}-${DD}-${HH}*.nc
  wait

  echo "Moving MOM restart MOM.res.${YY}-${MM}-${DD}-${HH}*.nc to HPSS: $HOUT"
  hsi put $MTAR : $HOUT/${MTAR}
  wait

  ntar=`hsi -P ls -1 $HOUT | grep ${MTAR} | wc -l`
  echo $ntar
  if [[ $ntar == 0 ]]; then
    echo "!!! $MTAR not found on HPSS $HOUT !!!"
  else
    touch $flchck
  #
    echo "$MTAR is on HPSS, removing local $MTAR"
    /bin/rm -f $MTAR
  fi

  cd $DRUN 
fi

#
# DATM coupled restart
cd $DRUN/RESTART
pwd
FLDATM=DATM_GEFS.cpl.r.${YY}-${MM}-${DD}-00000.nc
ls -l ${FLDATM}
nrst=`ls -1 $FLDATM 2>/dev/null | wc -l`
flchck=DATM_GEFS_${YY}-${MM}-${DD}-${HH}.sent2hpss
if [[ $nrst == 0 ]]; then
  echo "$FLDATM restart not found"
#  exit 1
elif [[ -f $flchck ]]; then
  echo "$FLDATM sent to HPSS, no action taken"
else
  echo "Tarring $FLDATM"
  ATMTAR=DATM_GEFS.cpl.${YY}-${MM}-${DD}-${HH}.tar.gz
  tar -cvzf ${ATMTAR} ${FLDATM}
  wait

  echo "Moving DATM restart $FLDATM to HPSS: $HOUT"
  hsi put $ATMTAR : $HOUT/${ATMTAR}
  wait

  ntar=`hsi -P ls -1 $HOUT | grep ${ATMTAR} | wc -l`
  echo $ntar
  if [[ $ntar == 0 ]]; then
    echo "!!! $ATMTAR not found on HPSS $HOUT !!!"
  else
    touch $flchck 
  #
    echo "$ATMTAR is on HPSS, removing local $ATMTAR"
    /bin/rm -f $ATMTAR
  fi

  cd $DRUN
fi




exit 0


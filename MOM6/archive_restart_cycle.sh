#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J MOMCICE_restart
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=03:00:00
#
# archive restart files and transfer to HPSS
# for cycle = CYC in the current run:
# mom6 restarts, cice, datm.r 
#
# use htar for creating POSIX-compatible tar files
# for easier access from HPSS
#
#
# Usage:
# sbatch archive_restart_cycle.sh CYC=[1, ... ]
# then the code uses list_cycles.txt to determine dates
# OR 
# sbatch archive_restart_cycle.sh YY MM DD [HH, if not HH=0]
#
# NOAA/NWS/EMC Dmitry Dukhovskoy  2023
#
set -u 

export expt=003
export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6_${expt}
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6/expt_${expt}
export SRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export ATMF=CFSR
export DUMP=$DRUN/RESTART/DUMP
export SENT=$DRUN/RESTART/SENT

mkdir -pv $SENT

CYC=0
if [[ $# == 1 ]]; then
  CYC=$1
# Get rid of leading 0 in CYC if there is
  CYC=$(( 10#$CYC ))

  cd $DRUN

  # Restart date for current cycle:
  dStart=`grep "^cycle[ ]*${CYC}, " list_cycles.txt | cut -d ":" -f2`

  YY=$(echo $dStart | cut -d ' ' -f1)
  MM=$(echo $dStart | cut -d ' ' -f2)
  DD=$(echo $dStart | cut -d ' ' -f3)
  HH=$(echo $dStart | cut -d ' ' -f4)

  printf "Archiving restarts for cycle ${CYC} Start: $YY/$MM/$DD:$HH\n"
elif [[ $# == 3 ]] || [[ $# == 4 ]]; then
  YY=$1
  MM=$2
  DD=$3
  [[ $# == 4 ]] && HH=$4 || HH=0

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

flchck=restarts_${YY}-${MM}-${DD}-${HH}.sent2hpss
cd $DRUN/RESTART
if [[ -f $flchck ]]; then
  echo " Restarts ${YY}/${MM}/${DD}/${HH} sent to HPSS, no action taken " 
  exit 1
fi

FTAR=restarts_${YY}-${MM}-${DD}-${HH}
hsi mkdir -p $HOUT
mkdir -pv $DUMP

cd $DRUN
FDATM=DATM_${ATMF}.datm.r.${YY}-${MM}-${DD}-00000.nc
nrst=`ls -1 $FDATM 2>/dev/null | wc -l`
if [[ $nrst == 1 ]]; then
  echo "Moving $FDATM to HPSS:$HOUT"
  /bin/mv $FDATM $DUMP/.
else
# Can be in DUMP dir already
  echo "$FDATM not found, will check $DUMP"
fi

# CICE restart:
first=iced
cd $DRUN/RESTART
pwd
nrst=$( ls -l ${first}.${YY}-${MM}-${DD}*.nc | wc -l )
if [[ 10#$nrst > 0 ]]; then
  /bin/mv ${first}.${YY}-${MM}-${DD}*.nc $DUMP/.
else
  echo "CICE restarts not found, will check $DUMP"
fi

# MOM restart:
cd $DRUN/RESTART
#ls -l MOM.res.${YY}-${MM}-${DD}*.nc
nrst=`ls -1 MOM.res.${YY}-${MM}-${DD}-${HH}*.nc 2>/dev/null | wc -l`
if [[ 10#$nrst > 0 ]]; then
  /bin/mv MOM.res.${YY}-${MM}-${DD}-${HH}*.nc $DUMP/.
else
  echo "MOM restarts not found, will check $DUMP"
fi


#
# DATM coupled restart
cd $DRUN/RESTART
pwd
FLDATM=DATM_${ATMF}.cpl.r.${YY}-${MM}-${DD}-00000.nc
#ls -l ${FLDATM}
nrst=`ls -1 $FLDATM 2>/dev/null | wc -l`
if [[ 10#$nrst > 0 ]]; then
  /bin/mv ${FLDATM} $DUMP/.
else
  echo "$FLDATM restart not found, will check $DUMP"
fi

cd $DUMP
ls -l *${YY}*${MM}*${DD}*
nrst=$( ls -l *${YY}*${MM}*${DD}*.nc | wc -l )
if [[ $nrst == 0 ]]; then
  echo "No restarts found, exit ..."
  exit 5
fi

chck_file=restarts_${YY}${MM}${DD}${HH}.sent2hpss
flst=listtar_${YY}${MM}${DD}${HH}.txt
/bin/rm -f $flst

ls -1 *${YY}*${MM}*${DD}* > $flst

echo "Sending to HPSS"
htar -cvf $HOUT/${FTAR}.tar -L $flst  > ${FTAR}.tar.log
wait

# Check success:
tar_success=$(cat ${FTAR}.tar.log | grep -c 'HTAR SUCCESSFUL')

if [[ $tar_success == 0 ]] ; then
  echo "!!! HTAR FAILED $FTAR !!!"
  exit 5
else
  echo "${FTAR}.tar.gz is on HPSS"
  touch $DRUN/RESTART/SENT/$chck_file
#
# Remove *nc
#  echo "${FTAR}.tar.gz is on HPSS, removing local ${FTAR}.tar.gz"
#   /bin/rm -f $ftar
  echo "Removing tarred files from the list"
  for fl in $( cat $flst ); do
    echo $fl
    /bin/rm $fl
  done

fi

exit 0


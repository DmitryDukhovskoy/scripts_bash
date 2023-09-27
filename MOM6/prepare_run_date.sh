#! /bin/sh -x
# Prepare data/restart pointers & restart files 
# for a new run starting on YYYY MM DD 
# HH by default = 0 otherwise 
# specify HH as an input
# Usage:
# 
set -u

if [[ $# < 3 ]]; then
  echo " ERROR: input YYYY MM DD [HH] of start date"
  echo " Usage: ./prepare_run.sh YYYY MM DD [HH] "
  echo " HH - optional, default 00"
  exit 1
else
  export YY=$1
  export MM=$2
  export DD=$3

  if [[ $# == 4 ]]; then
    export HH=$4
  else
    export HH=00
  fi
fi

  
printf "Preparing run for $YY/$MM/$DD:$HH\n"

export DEXE=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/MOM6/ufs-weather-model/tests
export HEXE=fv3_001.exe

printf "MOM6/CICE6 executable: \n"
ls -rlt $DEXE/$HEXE

touch $HEXE
/bin/rm $HEXE

/bin/cp $DEXE/$HEXE .


# File pointer atm data:
fdatm="DATM_GEFS_NEW.datm.r.${YY}-${MM}-${DD}-${HH}000.nc"
if [ ! -f "$fdatm" ]; then
  printf "ERR: $fdatm is not found\n"
  exit 1
fi
#touch $fdatm
fpnt=rpointer.atm
touch $fpnt
/bin/rm $fpnt
echo $fdatm > $fpnt


# Coupler pointer:
fdcplr="RESTART/DATM_GEFS_NEW.cpl.r.${YY}-${MM}-${DD}-${HH}000.nc"
if [ ! -f "$fdcplr" ]; then
  printf "ERR: $fdcplr is not found\n"
  exit 1
fi
fcpl=rpointer.cpl
touch $fcpl
/bin/rm $fcpl
echo $fdcplr > $fcpl

# Sea ice restart file pointer:
fcice="./RESTART/iced.${YY}-${MM}-${DD}-${HH}000.nc"
if [ ! -f "$fcice" ]; then
  printf "ERR: $fcice is not found\n"
  exit 1
fi
fcpntr=ice.restart_file
touch $fcpntr
/bin/rm $fcpntr
echo $fcice > $fcpntr

# Check MOM restart:
for ii in 0 1 2 3
do
  if [[ $ii == 0 ]]; then
    sfx=""
  else
    sfx="_$ii"
  fi

  fmom="MOM.res.${YY}-${MM}-${DD}-12-00${sfx}.nc"

  if [ ! -f RESTART/${fmom} ]; then
    printf "ERR: RESTART/$fmom is not found\n"
    exit 1
  fi
done

./check_run.sh

exit 0
  





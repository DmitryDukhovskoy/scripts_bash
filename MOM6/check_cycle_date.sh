#! /bin/bash
#  
# For running multiple cycles, check
# start end days for a cycle
# 
# Usage: ./check_cycle_date.sh YY MM DD HH dday CYC
#  YY/MM/DD : HH - start of the simulation, day1, dday - # of days in 1 run cycle
#
# Dmitry Dukhovskoy, NOAA/NWS/NCEP/EMC
#
set -u

export DSRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export WD=`pwd`
export RD=$WD/RESTART
export DINP=$WD/INPUT
export FINP=run_cycles.txt
export FOUT=list_cycles.txt

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

if [[ $# < 6 ]]; then
  echo " Usage: ./check_cycle_date.sh YY MM DD HH dday CYC"
  exit 1
fi

YY0=$1
MM0=$2
DD0=$3
HH0=$4
dday=$5
ncyc=$6

for (( icyc = 1; icyc <= ncyc; icyc = icyc+1 ))
do
# End day of the cycle: 
  dEnd=`echo "ADD DAYS" | awk -f dates.awk yr1=$YY0 mo1=$MM0 d1=$DD0 ndays=$dday`
#  echo "dEnd = $dEnd"
  YYE=`echo $dEnd | cut -d ' ' -f1`
  MME=`echo $dEnd | cut -d ' ' -f2`
  DDE=`echo $dEnd | cut -d ' ' -f3`

  if [[ $icyc == $ncyc ]]; then
    echo "cycle $icyc : $YY0 $MM0 $DD0 $HH0 : $YYE $MME $DDE $HH0" 
  fi
  
  export YY0=$YYE
  export MM0=$MME
  export DD0=$DDE
done
  

exit 0
  





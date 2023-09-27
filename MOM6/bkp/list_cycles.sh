#! /bin/bash
#  
# For running multiple cycles, prepare list of cycles with
# start end days
# 
# nhours_fcst 
# nhours_fcst have to be divisible by 24 giving integer N. of days!
#
# Usage: ./list_cycles.sh 
# Will need an input file FINP with this info:
#
# year0/month0/day0/hr0 - beginning of the simulation
# dhr - hours, duration of 1 cycle
#       must be divisible by 24 hr = # of integer days
# ncycles - # of cycles for the total run
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

while read -r line;
do
  fld=`echo ${line} | cut -d ":" -f 1`
  if [[ $fld == "start_year" ]]; then
    YY=`echo ${line} | cut -d ":" -f 2`
  elif [[ $fld == "start_month" ]]; then
    MM=`echo ${line} | cut -d ":" -f 2`
  elif [[ $fld == "start_day" ]]; then
    DD=`echo ${line} | cut -d ":" -f 2`
  elif [[ $fld == "start_hour" ]]; then
    HH=`echo ${line} | cut -d ":" -f 2`
  elif [[ $fld == "nhours_fcst" ]]; then
    dhr=`echo ${line} | cut -d ":" -f 2`
  elif [[ $fld == "ncycles" ]]; then
    ncyc=`echo ${line} | cut -d ":" -f 2`
  fi
done < "$FINP"

YY0=$(trim $YY)
MM0=$(trim $MM)
DD0=$(trim $DD)
HH0=$(trim $HH)
dhr=$(trim $dhr)
ncyc=$(trim $ncyc)

dday=$(( dhr/24 ))
 
printf "Preparing list of ${ncyc} cycles, starting ${YY0}/${MM0}/${DD0}:${HH0}\n"
printf "  Cycle duration: ${dday} days (${dhr} hrs) \n"


touch $FOUT
/bin/rm -f $FOUT
touch $FOUT

for (( icyc = 1; icyc <= ncyc; icyc = icyc+1 ))
do
# End day of the cycle: 
  dEnd=`echo "ADD DAYS" | awk -f dates.awk yr1=$YY0 mo1=$MM0 d1=$DD0 ndays=$dday`
#  echo "dEnd = $dEnd"
  YYE=`echo $dEnd | cut -d ' ' -f1`
  MME=`echo $dEnd | cut -d ' ' -f2`
  DDE=`echo $dEnd | cut -d ' ' -f3`

# Keep MM and DD in 01, 02, ... format
  MM0=`echo $MM0 | awk '{printf("%02d",$1)}'`
  DD0=`echo $DD0 | awk '{printf("%02d",$1)}'`
  echo "cycle $icyc, start, dhrs: $YY0 $MM0 $DD0 $HH0 $dhr" >> $FOUT

  export YY0=$YYE
  export MM0=$MME
  export DD0=$DDE
done

exit 0
  





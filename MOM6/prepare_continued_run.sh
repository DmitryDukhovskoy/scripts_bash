#! /bin/bash
#  
# Use this script 
# for continued simulation (cycles 2, 3, ...) following cycle 1
#
# First, modify model_configure start date and duration of the run 
# nhours_fcst
#
# Prepare data/restart pointers & restart files 
# for a new run starting on YYYY MM DD HH 
# Start time/date is read from model_configure 
# 
# Dmitry Dukhovskoy, NOAA/NWS/NCEP/EMC
#
set -u

export FINP=model_configure
export DSRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export WD=`pwd`
export RD=$WD/RESTART
export DINP=$WD/INPUT
export new_run=1  # =1 - new run, =0 - continued run

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
  fi

done < "$FINP"
YY=$(trim $YY)
MM=$(trim $MM)
DD=$(trim $DD)
HH=$(trim $HH)

  
printf "Preparing run for $YY/$MM/$DD:$HH\n"

#mkdir -pv ${DINP}
mkdir -pv ${WD}/bkp

export DEXE=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/MOM6/ufs-weather-model/tests
export HEXE=fv3_001.exe

printf "MOM6/CICE6 executable: \n"
ls -rlt $DEXE/$HEXE

touch $HEXE
/bin/rm $HEXE

/bin/cp $DEXE/$HEXE .


# File pointer atm data:
fdatm="DATM_GEFS.datm.r.${YY}-${MM}-${DD}-${HH}000.nc"
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
fdcplr="RESTART/DATM_GEFS.cpl.r.${YY}-${MM}-${DD}-${HH}000.nc"
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

# Update nems.configure file
# duration of the run
cd $WD
nhfcst=`grep nhours_fcst model_configure | cut -d ":" -f 2 | awk '{print $1}'` 
fnems=nems.configure
/bin/cp $fnems bkp/.
/bin/cp $fnems ${fnems}_1
sed -e "s|stop_n[ ]*=.*|stop_n = ${nhfcst}|g"\
    -e "s|restart_n[ ]*=.*|restart_n = ${nhfcst}|g" ${fnems}_1 > $fnems
/bin/rm ${fnems}_1
 

# Check MOM restart in RESTART 
# and INPUT
# When a new simulation is started:
# In RESTART should be restart files with date stamps
# e.g., MOM.res.2000-01-27-00-00_10.nc
# Need to rename those to MOM.res.nc and MOM.res_[1-...].nc
# Copy/move to INPUT
#
# If continued simulations (a new cycle within the same run):
# MOM.res.nc and MOM.res_*.nc will be created at the end of the cycle
# and put in the RESTART - need to ---> INPUT
# Change new_run = 0 for continued run
#
# Check missing MOM.res_?.nc exist if not - rename from 
# MOM.res.2000-01-27-00-00_10.nc 
#
export bname="MOM.res"
if [[ $new_run == 1 ]]; then
  cd ${DINP}
  nrst=`ls -1 ${bname}*nc 2>/dev/null | wc -l`
  echo "Found $nrst RESTART files in ${DINP}"

  cd ${WD}
  if [[ $nrst == 0 ]]; then
    printf " INPUT/${bname}_*.nc is not found\n"
    printf " Running rename_restart.sh to create missing restart"
  # Prepare restart:
    frst=rename_restart.sh
    if [ ! -f $frst ]; then
      echo "$frst is missing, fetching from $DSRC"
      /bin/cp $DSRC/$frst .
    fi

    chmod 750 $frst
    sed -i "s|export dstmp=.*|export dstmp=${YY}-${MM}-${DD}-${HH}|" $frst
    ./$frst ${YY} ${MM} ${DD} ${HH}
    wait
  fi
else
# Continued run, restart files MOM.res.nc and MOM.res_*.nc from previous cycle
# should be in RESTART
  cd $RD
  nrst=`ls -1 MOM.res_*.nc 2>/dev/null | wc -l`
  echo "Found $nrst RESTART files in ${DINP}"
  if [[ $nrst == 0 ]]; then
    printf " $RD/MOM.res_*.nc not found\n"
    printf " Restart from previous cycle missing"
    exit 1
  fi

  cd $DINP
  /bin/rm -f MOM.res.nc
  /bin/rm -f MOM.res_*.nc

  /bin/ln ${RD}/MOM.res.nc .
  /bin/ln ${RD}/MOM.res_*.nc .

fi

./check_run.sh

exit 0
  





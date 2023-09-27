#! /bin/bash -x
#  
# Use this script for beginning a new simulation and cycle 1
# for continued simulation (cycles 2, 3, ...) following cycle 1
# use prepare_continued_run.sh 
#
# First, modify model_configure start date and duration of the run 
# nhours_fcst 
# nhours_fcst have to be divisible by 24 giving integer N. of days!
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
export ncycles=14 # # of cycles in the simulation - total duration
export ATMF=CFSR

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
    dltHR=`echo ${line} | cut -d ":" -f 2`
  fi

done < "$FINP"
YY=$(trim $YY)
MM=$(trim $MM)
DD=$(trim $DD)
HH=$(trim $HH)
dltHR=$(trim $dltHR)

# Make sure MM and DD are in the format 01, 02, ...
MM=`echo $((MM)) | awk '{printf("%02d", $1)}'`
DD=`echo $((DD)) | awk '{printf("%02d", $1)}'`
  
printf "Preparing run for $YY/$MM/$DD:$HH\n"

#mkdir -pv ${DINP}
mkdir -pv ${WD}/bkp

#export DEXE=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/MOM6/ufs-weather-modelOLD/tests
export DEXE=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/MOM6/ufs-weather-model/tests
export UFSEXE=fv3_datm_cdeps_intel.exe
export HEXE=fv3_001.exe

printf "MOM6/CICE6 executable: \n"
ls -rlt $DEXE/$UFSEXE

touch $HEXE
/bin/rm $HEXE

/bin/cp $DEXE/$UFSEXE .
ln -sf $UFSEXE $HEXE

# File pointer atm data:
fdatm="DATM_${ATMF}.datm.r.${YY}-${MM}-${DD}-${HH}000.nc"
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
fdcplr="RESTART/DATM_${ATMF}.cpl.r.${YY}-${MM}-${DD}-${HH}000.nc"
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
# Remove old restart files and recreate new MOM6 restarts
cd $DINP
/bin/rm -f MOM.res.nc
/bin/rm -f MOM.res_*.nc
cd ${WD}

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

# Prepare run_cycle.txt for generating list_cycles.txt
  export fccl=run_cycles.txt
  touch $fccl
  /bin/rm -f $fccl
  touch $fccl

  grep 'start_year' $FINP >> $fccl
  grep 'start_month' $FINP >> $fccl
  grep 'start_day' $FINP >> $fccl
  grep 'start_hour' $FINP >> $fccl
  grep 'start_minute' $FINP >> $fccl
  grep 'start_second' $FINP >> $fccl
  grep 'nhours_fcst' $FINP >> $fccl
  echo "ncycles:                 $ncycles" >> $fccl

# Generate list with start dates for each cycle:
  ./list_cycles.sh
  
else
  echo "Use continue_run.sh"
fi

./check_run.sh

exit 0
  





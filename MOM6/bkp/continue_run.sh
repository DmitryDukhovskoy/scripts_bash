#! /bin/bash
#  
# Use this script for continued run 
# for continued simulation (cycles 2, 3, ...) following cycle 1
#
# All these already prepared on the fly:
#  data/restart pointers & restart files 
# 
# Dmitry Dukhovskoy, NOAA/NWS/NCEP/EMC
#
set -u

export FINP=model_configure
export DSRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export WD=`pwd`
export RD=$WD/RESTART
export DINP=$WD/INPUT
#export nhfcst=624
#export nhfcst=384


trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

if [[ $#<1 ]]; then
  printf " ERR: Usage ./continue_run.sh CYCLE_NUMBER\n"
  exit 1
fi

# Restart date for current cycle:
ncycle=$1 
dStart=`grep "cycle[ ]*${ncycle}" list_cycles.txt | cut -d ":" -f2`

YY=`echo $dStart | cut -d ' ' -f1`
MM=`echo $dStart | cut -d ' ' -f2`
DD=`echo $dStart | cut -d ' ' -f3`
HH=`echo $dStart | cut -d ' ' -f4`
nhfcst=`echo $dStart | cut -d ' ' -f5`

printf "Preparing cycle $ncycle Start: $YY/$MM/$DD:$HH duration=${nhfcst} hrs\n"

export DEXE=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/MOM6/ufs-weather-modelOLD/tests
export HEXE=fv3_001.exe

printf "MOM6/CICE6 executable: \n"
ls -rlt $DEXE/$HEXE

touch $HEXE
/bin/rm $HEXE
/bin/cp $DEXE/$HEXE .

# Update model_configure
/bin/cp $FINP ${FINP}_0
sed -e "s|start_year: .*|start_year:              ${YY}|"\
    -e "s|start_month: .*|start_month:             ${MM}|"\
    -e "s|start_day: .*|start_day:               ${DD}|"\
    -e "s|nhours_fcst: .*|nhours_fcst:             ${nhfcst}|"\
    -e "s|start_hour: .*|start_hour:              ${HH}|" ${FINP}_0 > $FINP

# File pointer atm data:
fdatm="DATM_GEFS.datm.r.${YY}-${MM}-${DD}-${HH}000.nc"
if [ ! -f "$fdatm" ]; then
  printf "ERR: $fdatm is not found\n"
  exit 1
fi
touch $fdatm
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
export sfx=00
export dstmp=${YY}-${MM}-${DD}-${HH}-${sfx}
# Continued run, restart files MOM.res.nc and MOM.res_*.nc from previous cycle
# should be in RESTART
# restart files dumped during previous cycles should have been renamed
# using arange_mom_restart.sh 
cd $RD
nrst=`ls -1 MOM.res.${dstmp}*nc 2>/dev/null | wc -l`
echo "Found $nrst RESTART files in ${RD}"
if [[ $nrst == 0 ]]; then
  printf " $RD/MOM.res.${dstmp}*.nc not found\n"
  printf " Restart from previous cycle missing"
  printf " Check if arange_mom_restart.sh was run\n"

  exit 1
fi

cd $DINP
/bin/rm -f MOM.res.nc
/bin/rm -f MOM.res_*.nc

cd $WD
frst=rename_restart.sh
if [ ! -f $frst ]; then
  echo "$frst is missing, fetching from $DSRC"
  /bin/cp $DSRC/$frst .
fi

chmod 750 $frst
sed -i "s|export dstmp=.*|export dstmp=${YY}-${MM}-${DD}-${HH}|" $frst
./$frst ${YY} ${MM} ${DD} ${HH}
wait


./check_run.sh

exit 0
  





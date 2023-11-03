#! /bin/bash
#  
# Wraper for continued run 
# for continued simulation (cycles 2, 3, ...) following cycle 1
#
# Dmitry Dukhovskoy, NOAA/NWS/NCEP/EMC
#
set -u

export DSRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export WD=`pwd`
export RD=$WD/RESTART
export DINP=$WD/INPUT
export HSUB=sub_mom6cice.sh
#export nhfcst=648   # 27 days
#export nhfcst=384   # for last cycle to finish on 01/01/

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

printf "Preparing run for cycle $ncycle Start: $YY/$MM/$DD:$HH\n"

pwd
echo "Clean run directory"
./clean.sh
wait

echo "Arranging MOM output"
./arrange_mom_output.sh
wait

echo "Arranging CICE output"
./arrange_cice_output.sh
wait

echo "Arranging MOM restart"
#./arrange_mom_restart.sh $YY $MM $DD $HH  # old restart format
./arrange_mom_restart_v2.sh $YY $MM $DD $HH
wait
if [[ $? != 0 ]]; then
  echo "Arranging MOM failed, exit"
  exit 3
fi

echo "Start continue_run.sh "
FRUN=continue_run.sh
#/bin/cp $FRUN ${FRUN}_0
#sed -i "s|export nhfcst=.*|export nhfcst=${nhfcst}|" $FRUN
chmod 750 $FRUN
./${FRUN} $ncycle
status=$?

#exit 5
if (( $status == 0 )); then
  echo " Submitting job "
  sbatch $HSUB
fi


exit 0
  





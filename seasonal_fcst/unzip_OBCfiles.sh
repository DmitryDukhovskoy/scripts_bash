#!/bin/bash
#
# unzip OBC files prepared at PPAN 
# and arrange them in the directories
#
# For unzipping/untarring all atmos and ocean input fields use:
# unzip_input_dailyOB.sh
#
set -u

export obs_dir='/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/obcs_spear_daily'

if [[ $# -lt 1 ]]; then
  echo "usage: ./unzip_OBCfiles.sh YR1 [YR2 ]"
  echo " Start/end years are missing"
  exit 1
fi

YR1=$1
YR2=$YR1
if [[ $# -eq 2 ]]; then
  YR2=$2
fi 

cd $obs_dir
pwd
ls -l

prfx='OBCs_spear_daily_init'
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do 
  for fl in $( ls ${prfx}${yr}*.gz ); do
    echo "Processing ${fl} ..."
    dmm=$( echo ${fl} | cut -d"_" -f5 )
#    ens=$( echo ${dmm:1:2} | awk '{printf("%02d", $1)}' )
    ens=${dmm:1:2}
    dir_new=${yr}_e${ens}
    mkdir -pv $dir_new
    /bin/mv $fl $dir_new/.
    gunzip $dir_new/${fl}
  done
done

echo "All done ..."
exit 0 


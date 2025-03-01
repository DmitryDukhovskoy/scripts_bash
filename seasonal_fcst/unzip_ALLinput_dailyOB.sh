#!/bin/bash
#
#SBATCH --output=logs/%j.out
#SBATCH --job-name=unzip_input_dailyOB
#SBATCH --time=120
##SBATCH --nodes=1 --ntasks=8
#SBATCH --partition=eslogin_c5
#SBATCH --clusters=es
#SBATCH --account=cefi
#
# Wrapper to check unzipped OB, atm forcing fields for dailyOB f/casts
# will unzip untar all input fields (ocean and atmos) for all years / months / ensemles
# if there are too many, better to use:
#
# usage: [sbatch] unzip_input_dailyOB.sh [YR] 
#
set -u

export DINP=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data

YR1=0
if [[ $# -gt 0 ]]; then
  YR1=$1
  echo "Requested year=$YR1"
fi

# OB files:
export obs_dir=$DINP/obcs_spear_daily
prfx='OBCs_spear_daily_init'

cd $obs_dir
if [[ $YR1 -gt 100 ]]; then
  nzip=$( ls -l ${prfx}*${YR1}*.gz 2> /dev/null | wc -l )
  echo "For ${YR1} found ${nzip} ${prfx}*.gz files in  $obs_dir"

else
  nzip=$( ls -l ${prfx}*.gz 2> /dev/null | wc -l )
  echo "Found total ${nzip} ${prfx}*.gz files in  $obs_dir"
fi

if [[ $nzip -gt 0 ]]; then
  for fl in $( ls ${prfx}*.gz ); do
    dmm=$( echo ${fl} | cut -d"_" -f5 )
#    ens=$( echo ${dmm:1:2} | awk '{printf("%02d", $1)}' )
    nchar=$( echo ${prfx} | wc -m )
    ncharS=$(( nchar-1 ))
    yr=${fl:${ncharS}:4}
    ens=${dmm:1:2}
    dir_new=${yr}_e${ens}

    if [[ $YR1 -gt 0 ]] && [[ $yr -ne $YR1 ]]; then
      continue
    fi

    echo "Processing ${fl} ..."
    mkdir -pv $dir_new
    /bin/mv $fl $dir_new/.
    gunzip $dir_new/${fl}
  done
fi

# Atmospheric forcing
export atm_dir=$DINP/atmos
prfx='spear_atmos_'

cd $atm_dir
nzip=$( ls -l ${prfx}*.tar.gz 2> /dev/null | wc -l )
echo "Atmos fields: Found ${nzip} ${prfx}*.gz files in  $atm_dir"

if [[ $nzip -gt 0 ]]; then
  for ftar in $( ls ${prfx}*.tar.gz ); do
    echo $ftar
    #spear_atmos_201304.tar.gz
    dmm=$( echo ${ftar} | cut -d"." -f1 )
    date_stamp=$( echo ${dmm} | cut -d"_" -f3 )
    yratm=${date_stamp:0:4}

#    echo $yratm
    if [[ $YR1 -gt 0 ]] && [[ $yratm -ne $YR1 ]]; then
      echo "Skipping $yratm "
      continue
    fi

    echo "Untarring $ftar"
    tar -xzvf $ftar
    status=$?
    if [[ $status == 0 ]]; then
      echo "Removing $ftar"
      /bin/rm $ftar
    fi
  done
fi

echo "unzipping forcing fields All Done"

exit 0

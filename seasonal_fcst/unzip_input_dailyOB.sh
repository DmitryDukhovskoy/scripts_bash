#!/bin/bash
# Wrapper to check unzipped OB, atm forcing fields for dailyOB f/casts
# will unzip untar all input fields (ocean and atmos) for all years / months / ensemles
# if there are too many, better to use:
# untar_atmos.sh: unzip_OBCfiles.sh YR1 [YR2 ]
# unzip_OBCfiles.sh: unzip_OBCfiles.sh YR1 [YR2 ]
#
set -u

export DINP=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data

# OB files:
export obs_dir=$DINP/obcs_spear_daily
prfx='OBCs_spear_daily_init'

cd $obs_dir
nzip=$( ls -l ${prfx}*.gz 2> /dev/null | wc -l )
echo "Found ${nzip} ${prfx}*.gz files in  $obs_dir"

if [[ $nzip -gt 0 ]]; then
  for fl in $( ls ${prfx}*.gz ); do
    echo "Processing ${fl} ..."
    dmm=$( echo ${fl} | cut -d"_" -f5 )
#    ens=$( echo ${dmm:1:2} | awk '{printf("%02d", $1)}' )
    nchar=$( echo ${prfx} | wc -m )
    ncharS=$(( nchar-1 ))
    yr=${fl:${ncharS}:4}
    ens=${dmm:1:2}
    dir_new=${yr}_e${ens}
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
echo "Found ${nzip} ${prfx}*.gz files in  $atm_dir"

if [[ $nzip -gt 0 ]]; then
  for ftar in $( ls ${prfx}*.tar.gz ); do
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

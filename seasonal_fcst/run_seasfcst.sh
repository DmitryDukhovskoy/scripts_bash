#!/bin/bash 
# 
# Generate XML for seasonal f/casts for months 1, 4, 7, 10 all ensmbles for 1 year
# and automatically submit runs
#
# Use xml template to generate an XML for specific forecast
# usage: ./create_seasfcst_xml.sh YRSTART MOSTART
# Day start: assumed day = 1 of the month
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DSRC=/ncrc/home1/Dmitry.Dukhovskoy/scripts/seasonal_fcst
export DXML=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst
export XMLTMP=NEPphys_seasfcst_template.xml

if [[ $# < 1 ]]; then
  echo "ERROR start year not specified"
  echo "usage: ./run_seasfcst.sh YRSTART"
  exit 1
fi

ystart=$1

cd $DOUT
for mstart in 01 04 07 10; do

  if [[ $ystart -eq 1993 && $mstart -eq 1 ]]; then
    echo "Skipping month $mstart for $ystart as 1st start month is April"
    continue
  fi

  echo "Preparing: ${ystart} ${mstart}" 
  $DSRC/create_seasfcst_xml.sh $ystart $mstart
  wait

  flxml=NEPphys_seasfcst_${ystart}_${mstart}.xml
  if [ ! -s $flxml ]; then 
    pwd
    ls -l
    echo "$flxml not generated - quitting"
    exit 5
  fi

  for ens in 01 02 03 04 05 06 07 08 09 10; do
    echo "Preparing run for $ystart $mstart $ens"
    frerun -s -x NEPphys_seasfcst_${ystart}_${mstart}.xml -p ncrc5.intel23 -t repro NEPphys_frcst_climOB_${ystart}-${mstart}-e${ens} --overwrite
  done
done

exit 0

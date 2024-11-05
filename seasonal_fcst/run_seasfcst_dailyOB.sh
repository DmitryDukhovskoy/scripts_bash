#!/bin/bash 
# 
# Generate XML for seasonal f/casts for months 1, 4, 7, 10 all ensmbles for 1 year
# and automatically submit runs
#
# 
# Use xml template to generate an XML for specific forecast
# ens 01 runs with 5day mean output and standard output fields
# all other ens runs - standard output fields only
#
# usage: ./run_seasfcst_dailyOB_xml.sh YRSTART [MOSTART]
# ./run_seasfcst_dailyOB_xml.sh YRSTART - will create xml's and submit jobs for
#                  all forecasts that start YRSTART Months=1,4,7,10 and all ensembles
# ./run_seasfcst_dailyOB_xml.sh YRSTART MOSTART   - will create xml's and submit jobs 
#                  all forecasts that start on YRSTART MOSTART day =1 all ensembles
#
# To run 1 particular ensemble start on Month Year - run manually create_seasfcst_dailyOB_xml.sh
# run frerun to generate the run script 
# and submit the job 
# 
# Day start: assumed day = 1 of the month
#
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DSRC=/ncrc/home1/Dmitry.Dukhovskoy/scripts/seasonal_fcst
export DXML=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst_dailyOB
export XMLTMP=NEPphys_seasfcst_dailyOB_template.xml
#export GFDLDIR=

if [[ $# -lt 1 ]]; then
  echo "ERROR start year not specified"
  echo "usage: ./run_seasfcst.sh YRSTART"
  exit 1
fi

ystart=$1
MM=0
if [[ $# -eq 2 ]]; then
  MM=$2
fi

sfx_end="-dayout"   # for 5-day output 
bnm=$( echo $XMLTMP | cut -d "_" -f-3 )

cd $DOUT
for mstart in 01 04 07 10; do
  if [[ $MM -gt 0 ]] && [[ $mstart -ne $MM ]]; then
    continue
  fi

  if [[ $ystart -eq 1993 && $mstart -eq 1 ]]; then
    echo "Skipping month $mstart for $ystart as 1st start month is April"
    continue
  fi

  echo "Preparing: ${ystart} ${mstart}" 
  flxml=${bnm}_${ystart}_${mstart}.xml
  $DSRC/create_seasfcst_dailyOB_xml.sh $ystart $mstart
  status=$?
  if [[ $status -eq 0 ]]; then
    echo "${flxml} created"
  else
    echo "ERROR: failed to create ${flxml} "
    exit 1
  fi

# Prepare xml for saving 5day + standard output fields
  echo "Preparing: ${ystart} ${mstart} 5-day output xml" 
  flxml5d=${bnm}_${ystart}_${mstart}${sfx_end}.xml
  $DSRC/create_seasfcst_dailyOB_xml.sh $ystart $mstart 1
  status=$?
  if [[ $status == 0 ]]; then
    echo "${flxml5d} created"
  else
    echo "ERROR: failed to create ${flxml5d} "
    exit 2
  fi

#echo $bnm
  if [ ! -s $flxml ]; then 
    pwd
    ls -l
    echo "$flxml not generated - quitting"
    exit 4
  fi
  if [ ! -s $flxml5d ]; then 
    pwd
    ls -l
    echo "$flxml5d not generated - quitting"
    exit 5
  fi

  for ens in 01 02 03 04 05 06 07 08 09 10; do
    echo "Preparing run for $ystart $mstart $ens"
    if [[ $ens == 01 ]]; then
      frerun -s -x ${flxml5d} -p ncrc5.intel23 -t repro NEPphys_frcst_dailyOB_${ystart}-${mstart}-e${ens} --overwrite
    else
      frerun -s -x ${flxml} -p ncrc5.intel23 -t repro NEPphys_frcst_dailyOB_${ystart}-${mstart}-e${ens} --overwrite
    fi
  done
done

exit 0

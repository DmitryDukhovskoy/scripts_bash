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
# Day start: assumed day = 1 of the month
#
# usage: ./run_seasfcst_dailyOB.sh YRSTART [MSTART] [ensemble]
#   run_seasfcst.sh YRSTART - prepare xml's to run all ensemlbes that start in YRSTART and months=1,4,7,10
#   run_seasfcst.sh YRSTART MSTART - -"- -"-  -"- all ensembles that start in YRSTART MSTART
#   run_seasfcst.sh YRSTART MSTART ENS - -"- -"-  -"- ensemble ENS that start in YRSTART MSTART
#
#
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DSRC=/ncrc/home1/Dmitry.Dukhovskoy/scripts/seasonal_fcst
export DXML=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst_dailyOB
export XMLTMP=NEPphys_seasfcst_dailyOB_template.xml
# expt number: 01 - with 1 SPEAR ens used to generate OBCs
#              02 - multi-ens OBCs, i.e. for each ens f/cast OB used corresponding SPEAR ens run
export expt_nmb=02   # <------  Check this before running the script 

if [[ ${expt_nmb} -eq 1 ]]; then
  echo "======================================================================================= "
  echo " --- 01: 1-ens OBs runs, SPEAR ens runs is fixed=01 for different fcast ens runs --- "
  echo "======================================================================================= "
elif [[ ${expt_nmb} -eq 2 ]]; then
  echo "======================================================================================= "
  echo " !!!! 02: Multi-ensemble OBs runs with different SPEAR ens for different fcast ens runs !!! "
  echo "======================================================================================= "
fi

if [[ $# -lt 1 ]]; then
  echo "ERROR start year not specified"
  echo "usage: ./run_seasfcst_dailyOB.sh YRSTART [MSTART] [ENS]"
  echo "e.g. run all ensembels for 1997/04:  run_seasfcst_dailyOB.sh 1997 4"
  echo "e.g. run ensembel 8 for 1997/04:     run_seasfcst_dailyOB.sh 1997 4 8"
  exit 1
fi

if [[ $# -gt 3 ]]; then
  echo "ERROR max input parameters 3"
  echo "usage: ./run_seasfcst_dailyOB.sh YRSTART [MSTART] [ENS]"
  exit 1
fi


ystart=$1
MM=0
ens_run=0
if [[ $# -eq 2 ]]; then
  MM=$2
fi

if [[ $# -eq 3 ]]; then
  MM=$2
  ens_run=$3
fi

sfx_end="-dayout"   # for 5-day output 
bnm=$( echo $XMLTMP | cut -d "_" -f-3 )
expt_name=NEPphys_frcst_dailyOB${expt_nmb}

cd $DOUT
for mstart in 01 04 07 10; do
  if [[ $MM -gt 0 ]] && [[ $mstart -ne $MM ]]; then
    continue
  fi

  if [[ $ystart -eq 1993 && $mstart -eq 1 ]]; then
    echo "Skipping month $mstart for $ystart as 1st start month is April"
    continue
  fi

#  flxml5d=${bnm}_${ystart}_${mstart}${sfx_end}_e{ens0}.xml

  for ens in 01 02 03 04 05 06 07 08 09 10; do
    if [[ ${ens_run} -gt 0 ]] && [[ 10#$ens -ne 10#${ens_run} ]]; then
      continue
    fi
    echo "Preparing run for $ystart month=$mstart ens=$ens"
    ens0=$( echo $ens | awk '{printf("%02d", $1)}')

    if [[ 10#${expt_nmb} -eq 1 ]]; then
      ens_spear=01         # fixed SPEAR ens for OBCs
    elif [[ 10#${expt_nmb} -eq 2 ]]; then
      ens_spear=$ens0
    fi

# Create XML's with OBs from a fixed SPEAR ens or multi-ens SPEAR OB
    flxml=${bnm}_${ystart}_${mstart}_e${ens0}.xml
    /bin/rm -f $flxml
    if [[ $ens == 01 ]]; then
      $DSRC/create_seasfcst_dailyOB_xml.sh $ystart $mstart $ens0 $ens_spear $expt_name 999
    else 
      /bin/rm -f $flxml
      $DSRC/create_seasfcst_dailyOB_xml.sh $ystart $mstart $ens0 $ens_spear $expt_name
    fi
    if [ ! -s $flxml ]; then 
      pwd
      ls -l
      echo "$flxml not generated - quitting"
      exit 5
    fi

#    if [[ $ens == 01 ]]; then
#      frerun -s -x ${flxml5d} -p ncrc5.intel23 -t repro ${expt_name}_${ystart}-${mstart}-e${ens0} --overwrite
#    else
    frerun -s -x ${flxml} -p ncrc5.intel23 -t repro ${expt_name}_${ystart}-${mstart}-e${ens0} --overwrite
#    fi
  done
done

exit 0

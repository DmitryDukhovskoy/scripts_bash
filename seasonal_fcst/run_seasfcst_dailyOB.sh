#!/bin/bash 
#  
# The MOM6-SIS2 executable should be created first, e.g.:
# in XML dir:
# dsd@gaea56:NEP_xml\> fremake -x NEPphys_seasfcstIrlx_dailyOB03_tmplt.xml -p ncrc5.intel23 -t repro FMS2_MOM6_SIS2_compile_irlx
# Using source directory = /gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily/FMS2_MOM6_SIS2_compile_irlx/src...
# 
# TO SUBMIT => sleep 1; sbatch /gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily/FMS2_MOM6_SIS2_compile_irlx/ncrc5.intel23-repro/exec/compile_FMS2_MOM6_SIS2_compile_irlx.csh
#
# Generate XML for seasonal f/casts for months 1, 4, 7, 10 all ensmbles for 1 year
# and automatically submit runs
#
# 
# Use xml template to generate an XML for specific forecast
# ens 01 runs with 5day mean output and standard output fields
# all other ens runs - standard output fields only
#
#
# use keyword and optional arguments for specifying the expt to run
# Check run_seasfcst_dailyOB_OLD.sh - old version that was used for 1st seas. f/casts expt02 
# usage: ./run_seasfcst_dailyOB.sh -d [expt_nmb: 3] -y [year start: 1993, ...] -m [month start: 1, ...,] 
#                                 -e[ens nmb: 7] -i [logical flag for ice relax]
#
# e.g.:
#  ./run_seasfcst_dailyOB.sh -d 3 -y 1994 -m 7 -e 5 -i  --> prepare XML and runs expt03 that starts
#                                                               1994 / 7 ens#=05 with ice relaxation
#  ./run_seasfcst_dailyOB.sh -d 3 - y 1993 --> prepare XML and runs expt03 that starts 1993 for
#                                              all months=1,4,7,10, and all ensmbls=1, ... 10
# Day start: assumed day = 1 of the month
#
#
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DSRC=/ncrc/home1/Dmitry.Dukhovskoy/scripts/seasonal_fcst
export DXML=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst_dailyOB
export DARCH=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily
export PLTF=ncrc5.intel23-repro
export XMLTMP=NEPphys_seasfcst_dailyOB_template.xml

# Set defaults:
# expt number: 01 - with 1 SPEAR ens used to generate OBCs
#              02 - multi-ens OBCs, i.e. for each ens f/cast OB used corresponding SPEAR ens run
#              03 - multi-ens OBCs, i.e. for each ens f/cast OB used corresponding SPEAR ens run with ice rlx
export expt_nmb=03   # <------  Check this before running the script 
export ystart=0      # this has to be specified
export MM=0
export ens_run=0
#export ice_relax=0
export irlx_rate=12  # strongest relaxation in the domain, hrs

# Function to print usage message
usage() {
  echo "Usage: $0 --exptn 3 [--ensn 4] [--ms 7] [--irlx 12] "
  echo "  --exptn   experiment number, default: ${expt_nmb}"
  echo "  --ys      year to start the f/cast, required" 
  echo "  --ms      month to start the f/cast, default: 1,4,7,10" 
  echo "  --ensn    ensemble # to run, default: all ensmbls: 1, ..., 10, ens=1 - N-day average output added to standard output"
  echo "  --irlx    max relaxation hours (e.g. 24), irlx=0 - no ice relax, default: ${irlx_rate}"
  exit 1
}

# Pars flags for optional arguments:
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      ystart="$2"
      shift 2
      ;;
    --exptn)
      expt_nmb="$2"
      shift 2
      ;;
    --ms)
      MM="$2"
      shift 2
      ;;
    --ensn)
      ens_run="$2"
      shift 2
      ;;
    --irlx)
      irlx_rate="$2"
      shift 2
      ;;
    *)
      echo "Error: Unrecognized option $1"
      usage
      ;;
  esac
done

if [[ $irlx_rate -gt 0 ]]; then
  XMLTMP='NEPphys_seasfcstIrlx_dailyOB_tmplt.xml'  # XML with ice relaxation directives
fi

if [[ -ystart -eq 0 ]]; then
  echo "ystart is required: ./run_seasfcst_dailyOB.sh -y 1993"
  usage
  exit 1
fi

if [[ ${expt_nmb} -eq 1 ]]; then
  echo "======================================================================================= "
  echo " --- 01: 1-ens OBs runs, SPEAR ens runs is fixed=01 for different fcast ens runs --- "
  echo "======================================================================================= "
elif [[ ${expt_nmb} -eq 2 ]]; then
  echo "======================================================================================= "
  echo " !!!! 02: Multi-ensemble OBs runs with different SPEAR ens for different fcast ens runs !!! "
  echo "======================================================================================= "
elif [[ ${expt_nmb} -eq 3 ]]; then
  echo "======================================================================================= "
  echo " !!!! 03: Multi-ensemble OBs runs with daily SPEAR ens + ice relax maxrlx ${irlx_rate}hrs!!! "
  echo "======================================================================================= "
fi

expt_nmb=$( echo $expt_nmb | awk '{printf("%02d", $1)}')
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
    echo "  "
    echo "Preparing run for $ystart month=$mstart ens=$ens"
    ens0=$( echo $ens | awk '{printf("%02d", $1)}')

    if [[ 10#${expt_nmb} -eq 1 ]]; then
      ens_spear=01         # fixed SPEAR ens for OBCs
    elif [[ 10#${expt_nmb} -eq 2 ]]; then
      ens_spear=$ens0
    elif [[ 10#${expt_nmb} -ge 3 ]]; then
      ens_spear=$ens0
    fi

# Check if the run exists
  dir_arch=$DARCH/${expt_name}_${ystart}-${mstart}-e${ens}/${PLTF}/archive/history
  fltar=${ystart}${mstart}01.nc.tar
  if [ -d $dir_arch ] && [ -s $dir_arch/${fltar} ]; then
    echo "Run already finished: $dir_arch/${fltar}"
    echo " Skipping ..."
    continue
  fi

# Create XML's with OBs from a fixed SPEAR ens or multi-ens SPEAR OB
    flxml=${bnm}_${ystart}_${mstart}_e${ens0}.xml
    /bin/rm -f $flxml
    if [[ $ens == 01 ]]; then
      $DSRC/create_seasfcst_dailyOB_xml.sh --ys $ystart --ms $mstart --ens $ens0 --enspr $ens_spear \
                                 --expt_name $expt_name --dayout 5 --xmltmp $XMLTMP --irlx $irlx_rate
    else 
      /bin/rm -f $flxml
      $DSRC/create_seasfcst_dailyOB_xml.sh --ys $ystart --ms $mstart --ens $ens0 --enspr $ens_spear \
                                 --expt_name $expt_name --xmltmp $XMLTMP --irlx $irlx_rate
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

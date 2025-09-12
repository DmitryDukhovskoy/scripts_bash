#!/bin/bash
#
# Transfer several output fields to PPAN for checking
# also send log file and/or SIS_parameter 
# usage: send_output_to_ppan.sh -d [expt_nmb] -f [icem or oceanm] -s [day start] -e[day end] \
#                        -l [a flag: save log] -p [a flag: save SIS_parameter.doc] -m [save monthly files]
# Year is determined from files saved in jdir, assuming this naming conventions YYYYMMDD.*.nc
set -u

regn=NEP
#export DOUTP=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_isponge_test
#export DOUTP=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEPphys_frcst_dailyOB04_2015-04-e01.o135461890
#export DPPAN=/work/Dmitry.Dukhovskoy/run_output/NEP_ISPONGE/1993/04
#export DPPAN0=/archive/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily

usage() {
  echo "Usage: $0 --yr 1994 --jdir NEPirlx_210820057..."
  #echo "  --yr     f/cast init year: 1993, ..., default: 2001 for NEP, 1995 for ARC" 
  echo "  --jdir   NEPirlx_210820057  where output moved after job finished"
  echo "  --ocnm   send oceanm_YYYY_MM.nc files, default = all files "
  echo "  --ice    send ice_daily, ice_monthly files, ocean_month default = all files"
  exit 1
}


echo "Region: ${regn}"

# Default values:
fsfx='icem'
sis_param=SIS_parameter_doc.all   # SIS parameter file
mom_param=MOM_parameter_doc.all
jdir=""
send_all=1
send_log=0
send_ice=0
send_ocnm=0
YR=0

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
#    --yr)
#      YR=$2
#      shift 2 # Move past the flag and its arg. to the next flag
#      ;;
    --jdir)
      jdir=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    --ocnm)
      send_ocnm=$2
      shift 2
      ;;
    --ice)
      send_ice=$2
      shift 2
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done
  
expt_name=NEPphys_nonudg_irlx_hcast
# Where the output are on gaea:
DOUTP=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/work/NEP_irlx_test
# Where to transfer on PPAN
DPPAN0=/archive/Dmitry.Dukhovskoy/fre/NEP/hindcast_phys/NEPphys_nonudg_irlx_hcast
log_out=SIS_irlx
MS=1

if [[ $send_ocnm -gt 0 ]] || [[ $send_ice -gt 0 ]]; then
  send_all=0
fi

if [[ $send_all -gt 0 ]]; then
  send_ocnm=1
  send_ice=1
  send_log=1
fi

DOUTP=${DOUTP}/${jdir}
MS=$( echo ${MS} | awk '{printf("%02d", $1)}')
cd $DOUTP
pwd


fl=$(ls ????????.*.nc 2>/dev/null | head -n 1)
YR="${fl:0:4}"

if [[ -z "$fl" ]]; then
  echo "ERR: No matching file found"
  exit 1
fi

YR="${fl:0:4}"

# Check if YR is a valid 4-digit number
if [[ "$YR" =~ ^[0-9]{4}$ ]] && [[ $YR -ge 1900 && $YR -le 2050 ]]; then
  echo "Extracted year: $YR"
else
  echo "ERR: check output file names, derived invalid year '$YR'"
  exit 2
fi

DPPAN=${DPPAN0}/${YR}
dstmp=${YR}${MS}01

echo "remote dir: $DPPAN"

if [[ $send_log -gt 0 ]]; then
  for fl in $( ls -rt ${log_out}.o* | tail -1 ); do
    echo "sending $fl --> gfdl:${DPPAN}/."
    if [[ -f "$fl" ]]; then
      gcp -cd $fl "gfdl:${DPPAN}/"
      if [[ $? -eq 0 ]]; then
        touch ${log_out}_sent2ppan
      else
        echo "Error: Failed to send ${log_out}"
      fi
    else
      echo "Warning: File ${log_out} not found"
    fi
  done

  for prm in $sis_param $mom_param; do
    echo "Sending $prm --> gfdl:${DPPAN}/"
    if [[ -f "$prm" ]]; then
      gcp -cd "$prm" "gfdl:${DPPAN}/"
      if [[ $? -eq 0 ]]; then
        touch "${prm}_sent2ppan"
      else
        echo "Error: Failed to send $prm"
      fi
    else
      echo "Warning: File $prm not found"
    fi
  done
fi

# ice daily and _month fields:
if [[ $send_ice -gt 0 ]]; then
  for mfls in ice_daily ocean_daily; do
    flday=${dstmp}.$mfls.nc
    echo "Saving daily ${flday} --> gfdl:${DPPAN}/." 
    if [ -s $flday ]; then
      echo "sending ${flday} --> gfdl:${DPPAN}/."
      gcp -cd ${flday} gfdl:${DPPAN}/
      if [[ $? -eq 0 ]]; then
        touch ${mfls}_sent2ppan
      else
        echo "transfer $mfls failed "
      fi
    else
      echo "Not found ${flday} "
    fi
  done

  for mfls in ice_month ocean_month; do
    flmnth=${dstmp}.$mfls.nc
    echo "Saving monthly ${flmnth} --> gfdl:${DPPAN}/."
    if [ -s $flmnth ]; then
      echo "sending ${flmnth} --> gfdl:${DPPAN}/."
      gcp -cd ${flmnth} gfdl:${DPPAN}/
      if [[ $? -eq 0 ]]; then
        touch ${mfls}_sent2ppan
      else
        echo "transfer $mfls failed "
      fi
    else
      echo "Not found ${flmnth}"
    fi
  done
fi

if [[ send_ocnm -gt 0 ]]; then
  for mm in 01 02 03 04 05 06 07 08 09 10 11 12; do
    flmnth=${dstmp}.oceanm_${YR}_${mm}.nc
    echo "Saving monthly ${flmnth} --> gfdl:${DPPAN}/."
    if [ -s $flmnth ]; then
      echo "sending ${flmnth} --> gfdl:${DPPAN}/."
      gcp -cd ${flmnth} gfdl:${DPPAN}/
      if [[ $? -eq 0 ]]; then
        touch oceanm_${YR}_${mm}_sent2ppan
      else
        echo "transfer $flmnth failed "
      fi
    else
      echo "Not found ${flmnth}"
    fi
  done
fi

echo "All done"
exit 0



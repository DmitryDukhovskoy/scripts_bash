#!/bin/bash
#
# Transfer several output fields to PPAN for checking
# also send log file and/or SIS_parameter 
# usage: send_output_to_ppan.sh -d [expt_nmb] -f [icem or oceanm] -s [day start] -e[day end] \
#                        -l [a flag: save log] -p [a flag: save SIS_parameter.doc] -m [save monthly files]
set -u

regn=NEP
#export DOUTP=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_isponge_test
#export DOUTP=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEPphys_frcst_dailyOB04_2015-04-e01.o135461890
#export DPPAN=/work/Dmitry.Dukhovskoy/run_output/NEP_ISPONGE/1993/04
#export DPPAN0=/archive/Dmitry.Dukhovskoy/fre/NEP/seasonal_daily

usage() {
  echo "Usage: $0 [--ys 1994] [--regn NEP] --expt 5 [--snday 1] [--sdaily 1] [--smnth 0] [--slog 1] [--sparam 1] [--jdir ARC12_209784479]..."
  echo "  --ys     f/cast init year: 1993, ..., default: 2001 for NEP, 1995 for ARC" 
  echo "  --regn   NEP or ARC"
  echo "  --days   day to start, 1,..., 366, default=1"
  echo "  --daye   day to end, default = 366" 
  echo "  --expt   expt number = 1, ... "
  echo "  --all    set all flags = 1, overrides individaul flags if all > 0"
  echo "  --jdir   subdir where output moved after job finished, ARC12_209777002, default=none"
  echo "  --slog   save log file = 1, default=0"
  echo "  --sparam save param file SIS_param, MOM_param =1, default=0"
  echo "  --snday  save N-daily averaged individ. output ocean and ice fields, default=1 yes"
  echo "  --sdaily save daily output ocean and ice fields ice_daily.nc"
  echo "  --smnth  save monthly ice/ocean files ice_month.nc  =1, default=1"
  exit 1
}


echo "Region: ${regn}"

# Default values:
fsfx='icem'
save_param=0
save_log=0
save_mnthly=0 # save ice/ocean_month.nc
save_daily=0  # save ice_daily.nc ocean_daily.nc 
save_nday=0   # save oceanm/icem_YYYY_DDD.nc N-daily avrg files
save_all=0    # save all output and log
expt_nmb=999
YS=0         # f/cast initialization year
MS=0           # f/cast initialization month
dayS=1
dayE=1000
sis_param=SIS_parameter_doc.all   # SIS parameter file
mom_param=MOM_parameter_doc.all
jdir=""

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YS=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --regn)
      regn=$2
      shift 2
      ;;
    --days)
      dayS=$2
      shift 2
      ;;
    --daye)
      dayE=$2
      shift 2
      ;;
    --expt)
      expt_nmb=$2
      shift 2
      ;;
    --all)
      save_all=$2
      shift 2
      ;;
    --slog)
      save_log=$2
      shift 2
      ;;
    --sparam)
      save_param=$2
      shift 2
      ;;
    --sdaily)
      save_daily=$2
      shift 2
      ;;
    --snday)
      save_nday=$2
      shift 2
      ;;
    --smnth)
      save_mnthly=$2
      shift 2
      ;;
    --jdir)
      jdir=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done
  
#if [[ ${MS} -eq 0 ]]; then
#  echo "ERR: MS was not specified $MS"
#  usage
#fi  

if [ $regn = 'NEP' ]; then 
  expt_name=NEPphys_expt
  # Where the output are on gfdl:
  DOUTP=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/work/NEP_irlx_test
  # Where to transfer on PPAN
  DPPAN0=/archive/Dmitry.Dukhovskoy/fre/NEP/test_ice_relax
  log_out=SIS_irlx
  YRR=2001
  MS=1
elif [ $regn = 'ARC' ]; then
  expt_name=ARCphys_expt
  DOUTP=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/work/ARC12_irlx_test
  DPPAN0=/archive/Dmitry.Dukhovskoy/fre/ARC12/test_ice_relax
  log_out=ARC_irlx
  YRR=1995
  MS=1
else
  echo "Unknown region: $regn"
  exit 1
fi

if [[ $YS -eq 0 ]]; then
  YS=$YRR
fi  
#

if [[ ${expt_nmb} -gt 100 ]]; then
  echo "ERR: expt was not specified ${expt_nmb}"
  usage
fi  

if [[ ${save_all} -gt 0 ]]; then
  save_param=1
  save_log=1
  save_mnthly=1
  save_daily=1
  save_nday=1
fi

echo "save_param  = ${save_param}"
echo "save_log    = ${save_log}"  
echo "save_mnthly = ${save_mnthly}"
echo "save_daily  = ${save_daily}"
echo "save_nday   = ${save_nday}"

DOUTP=${DOUTP}/${jdir}
enmb=$( echo ${expt_nmb} | awk '{printf("%02d", $1)}')
MS=$( echo ${MS} | awk '{printf("%02d", $1)}')
#DPPAN=${DPPAN0}/NEPphys_frcst_dailyOB-expt${enmb}/${YS}-${MS}-e01/history
DPPAN=${DPPAN0}/${expt_name}${enmb}/${YS}-${MS}
dstmp=${YS}${MS}01

cd $DOUTP
pwd

if [[ "$save_log" -eq 1 ]]; then
    echo "Log will be saved."
else
    echo "Log saving is not enabled."
fi
if [[ "$save_param" -eq 1 ]]; then
  echo "SIS_param  & MOM_param file will be saved."
else
  echo "SIS_param & MOM_param file saving is not enabled."
fi

echo "Experiment Number: $expt_nmb"
if [[ ${save_nday} -gt 0 ]]; then
  echo "N-day avrg  output fields saved for:"
  echo "   Start Day: $dayS"
  echo "   End Day: $dayE"
fi

echo "remote dir: $DPPAN"

if [[ ${save_nday} -gt 0 ]]; then
  echo "Saving N-day averaged output "
  for fsfx in icem oceanm; do  
    echo "Saving $fsfx"
    nfls=$( ls ${dstmp}.${fsfx}_????_???.nc 2>/dev/null | wc -l )
    if [[ $nfls -eq 0 ]]; then
      echo "No N-day avrg outputs for $dstmp:  ${nfls} ..."
      continue
    fi

    shopt -s nullglob
    for fl in ${dstmp}.${fsfx}_????_???.nc; do
      dmm=$( echo ${fl} | cut -d"." -f2 | cut -d"_" -f3 | awk '{printf("%d", $1)}')
      #echo $dmm
      if [[ $dmm -ge $dayS ]] && [[ $dmm -le $dayE ]]; then
        echo "sending $fl --> gfdl:${DPPAN}/."
    #    gcp -cd $fl gfdl:${DPPAN}/.
        gcp -cd $fl gfdl:${DPPAN}/   # temporary patch --batch
      if [[ $? -eq 0 ]]; then
        touch "${fsfx}_sent2ppan"
      fi
      fi
    done
    shopt -u nullglob

  done
else
  echo "Daily output are not transferred to PPAN"
fi

if [[ ${save_log} -gt 0 ]]; then
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
fi

if [[ ${save_param} -gt 0 ]]; then
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

# Daily fields:
if [[ ${save_daily} -gt 0 ]]; then
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
fi

if [[ ${save_mnthly} -gt 0 ]]; then
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


echo "All done"
exit 0



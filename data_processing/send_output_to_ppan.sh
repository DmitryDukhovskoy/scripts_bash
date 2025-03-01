#!/bin/bash
#
# Transfer several output fields to PPAN for checking
# also send log file and/or SIS_parameter 
# usage: send_output_to_ppan.sh -d [expt_nmb] -f [icem or oceanm] -s [day start] -e[day end] \
#                               -l [a flag: save log] -p [a flag: save SIS_parameter.doc
set -u

export DOUTP=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_isponge_test
#export DPPAN=/work/Dmitry.Dukhovskoy/run_output/NEP_ISPONGE/1993/04
export DPPAN0=/archive/Dmitry.Dukhovskoy/fre/NEP/test_ice_relax

cd $DOUTP

# Default values:
fsfx='icem'
save_param=0
save_log=0
expt_nmb=99
YS=1993         # f/cast initialization year
MS=04           # f/cast initialization month
dayS=0
dayE=1000
sis_param=SIS_parameter_doc.all   # SIS parameter file
log_out=SIS_sponge

# Pars flags for optional arguments:
while getopts "d:f:s:e:lp" opt; do
  case $opt in
    d)
      expt_nmb="$OPTARG"
      ;;
    f)
      fsfx="$OPTARG"
      ;;
    s)
      dayS="$OPTARG"
      ;;
    e)
      dayE="$OPTARG"
      ;;
    l)
      save_log=1     # Boolean flag fo saving log file
      ;;
    p)
      save_param=1   # Boolean flag for saving SIS_param file 
      ;;
    *)
      echo "unrecognized option / flag"
      echo "Usage $0 -d <expt_nmb> -f <icem or oceanm> -s <start day> -e <end day> [-l save log] [-p save param]"
      exit 1
      ;;
  esac
done 

enmb=$( echo ${expt_nmb} | awk '{printf("%02d", $1)}')
DPPAN=${DPPAN0}/NEPphys_expt${enmb}/${YS}-${MS}

echo "Experiment Number: $expt_nmb"
echo "File Suffix: $fsfx"
echo "Start Day: $dayS"
echo "End Day: $dayE"
if [ "$save_log" -eq 1 ]; then
    echo "Log will be saved."
else
    echo "Log saving is not enabled."
fi
if [ "$save_param" -eq 1 ]; then
    echo "SIS_param file will be saved."
else
    echo "SIS_param file saving is not enabled."
fi

echo "remote dir: $DPPAN"

#if [[ $# -gt 0 ]]; then
#  fsfx=$1
#fi
#
#if [[ $# -gt 1 ]]; then
#  dayS=$2
#  dayE=$3
#fi
  
for fl in $( ls *.${fsfx}_????_???.nc ); do
  dmm=$( echo ${fl} | cut -d"." -f2 | cut -d"_" -f3 | awk '{printf("%d", $1)}')
  #echo $dmm
  if [[ $dmm -ge $dayS ]] && [[ $dmm -le $dayE ]]; then
    echo "sending $fl --> gfdl:${DPPAN}/."
    gcp -cd $fl gfdl:${DPPAN}/.
  fi
done

if [[ $save_log -eq 1 ]]; then
  for fl in $( ls -rt SIS_sponge.o* | tail -1 ); do
    echo "sending $fl --> gfdl:${DPPAN}/."
    gcp -cd $fl gfdl:${DPPAN}/.
  done
fi

if [[ $save_param -eq 1 ]]; then
  echo "sending $sis_param --> gfdl:${DPPAN}/."
  gcp $sis_param gfdl:${DPPAN}/.
fi

echo "All done"
exit 0



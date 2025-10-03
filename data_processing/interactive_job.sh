#!/bin/bash 
#
# Run interactive job 
# for python etc
set -u

debug=F
thr=4
tmin=0
FS=6   # File system on Gaea F6 or F5
ACT=sfs-emc

usage() {
  echo "Usage: $0 --debug T/t or F/f "
  echo "  --debug  T: get interactive job in debug queue, default = ${debug} "
  echo "  --thr    time, hours, default = 4, for debug=0, =0 if tmin>0"
  echo "  --tmin   time, minutes, for debug=30"
  echo "  --FS     5 or 6, Gaea file system,  default=${FS}"
  echo "  --ACT    account to use for interactive job, default=${ACT}"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --debug)
      debug=${2^^}
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --thr)
      thr=$2
      shift 2
      ;;
    --tmin)
      tmin=$2
      shift 2
      ;;
    --FS)
      FS=$2
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ "${debug}" == T ]]; then
  if [[ $thr -gt 0 ]]; then
    thr=0
  fi
  if [[ $tmin -eq 0 ]]; then
    tmin=30
  fi
fi

if [[ $tmin -gt 0 ]]; then
  thr=0
fi

machine=$(uname -n)
if [[ ${machine} == h* ]]; then
    # hera or hercules
    if [[ "${debug}" == T ]]; then
        salloc --x11=first -q debug -t 0:${tmin}:00 --nodes=1 -A ${ACT} --exclusive
    else
        salloc --x11=first -t ${thr}:${tmin}:00 --nodes=1 -A ${ACT} --exclusive
    fi
elif [[ ${machine} == gaea* ]]; then
    echo "gaea F${FS}"
    salloc --x11=first -t ${thr}:${tmin}:00 --qos=hpss --partition=dtn_f5_f6 --constraint=f${FS} --nodes=1 -A ${ACT} #--exclusive
fi

#source ~/.bashrc


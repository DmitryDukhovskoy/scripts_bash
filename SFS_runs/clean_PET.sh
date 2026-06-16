#!/bin/bash
# 
set -u

# Help message function
show_help() {
    echo "Usage: ./clean_PET.sh [-rm] [-help]"
    echo
    echo "Options:"
    echo "  -rm        Remove files (permanent cleanup)"
    echo "  -help      usage"
    echo "  no flags   move to PET_tmp"
    exit 1
}

DPET=PET_tmp
rmpet=0
if [[ $# -gt 0 ]]; then
  case "$1" in
    -rm|--rm)
      echo "Remove mode: removing PET*.ESMF_LogFile"
      rmpet=1
      ;;
    -help|--help)
      show_help
      ;;
    *)
      echo "Unknown or no option provided."
      show_help
      ;;
  esac
fi

# Save log from PEs that run mediator, ocean, cice:
if [[ $rmpet -eq 1 ]]; then
  for ip in 000 100 200; do
    fll=PET${ip}.ESMF_LogFile
    if [ -f $fll ]; then
      mv $fll dmm_PET${ip}
    fi
  done
  rm -rf PET*_LogFile
  
  for ip in 000 100 200; do
    fll=PET${ip}.ESMF_LogFile
    if [ -f $fll ]; then 
      mv dmm_PET${ip} ${fll}
    fi
  done
else
  if [ ! -d ${DPET} ]; then
    echo "Not found $DPET, exiting ..."
    exit 1
  fi

  echo "Moving PET*_LogFile ---> ${DPET}"
  mv PET*_LogFile ${DPET}/.
fi

exit 0


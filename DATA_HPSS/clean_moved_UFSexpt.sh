#!/bin/bash
#SBATCH --job-name="xferUFS2hpss"
#SBATCH --account=sfs-cpu
#SBATCH --clusters=es
#SBATCH --partition=dtn_f5_f6
#SBATCH --constraint=f6
##SBATCH --qos=normal
#SBATCH --qos=dtn
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -e logs/%x.err%j
#SBATCH --output=logs/%x.o%j
set -ue

expt_name="ufs_datm_mx025"
enmb=""
ENMBS=()
rmall=0
check=0
tag="sent_to_hpss"  # tag inidcating successfull transfer to HPSS
DOUT=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy

# Transfer experiments from scratch dir to HPSS
# HPSS structure:
# /PORTFOLIO/PROJECT/RETENTION
#
usage() {
  echo "Usage: sbatch $0 --expt ufs_datm_mx025 --check 0 [--enmb 0 or 1 20 31 ]  "
  echo "  --ename   experiment name, default=${expt_name}"
  echo "  --check  =1: print expt numbers that can be deleted without deleting; default=${check}"
  echo "  --enmb   list of experiment numbers to be cleaned if have been transferred, e.g. 1 33 15  " 
  echo "  --rmall  =1: rm files and dirs; =0: rm files, keep directories empty, default=${rmall}"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enmb)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        ENMBS+=("$1")
        shift
      done
      ;;
    --check)
      check="$2"
      shift 2
      ;;
    --rmall)
      rmall="$2"
      shift 2
      ;;
    --ename)
      expt_name="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      usage
      ;;
  esac
done

if [[ ${#ENMBS[@]} -eq 0 ]]; then
  # Default: depete all experiments that have been transferred
  ENMBS=(0)
fi

#module load hpss

DEXP="${DOUT}/${expt_name}"
#DHPSS="/NCEPDEV/${proj}/${reten}year/${USER}/UFS_cice_testruns/${expt_name}"


cd $DEXP || { echo "Cannot cd to ${DEXP}"; exit 1; }
pwd

# Construct array of all expt dirs if expt nmb not provided
if [[ "${ENMBS[0]}" -eq 0 ]]; then
  ENMBS=()
  for d in expt[0-9]*; do
    [[ -d "$d" ]] || continue
    nmb="${d#expt}"
    ENMBS+=("$nmb")
  done
fi

for expt_nmb in "${ENMBS[@]}"; do
  if [[ ! "$expt_nmb" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid experiment number: $expt_nmb"
    continue
  fi

  printf -v dir_expt "expt%02d" "$expt_nmb"

  if [[ ! -d $dir_expt ]]; then
    echo "${dir_expt} not found at ${DEXP}"
    continue
  fi

  if [[ -f "${dir_expt}/${tag}" ]]; then

    if [[ "$check" -eq 1 ]]; then
      echo "${dir_expt} has been archived on HPSS can be deleted "
      cat ${dir_expt}/${tag}
      continue
    fi

    if [[ "$rmall" -eq 1 ]]; then
      echo "Deleting all: ${dir_expt}"
      rm -rf ${dir_expt}
    else
      # Delete all files (except $tag) recursively leaving dir structure
      echo "Deleting files ${dir_expt}"
      find "$dir_expt" -type f ! -name "$tag" -delete
    fi
  else
    echo "  ***  ${dir_expt} has NOT been archived on HPSS -- skipping"
  fi

done

du -h --max-depth=1

echo "All Done"

exit 0


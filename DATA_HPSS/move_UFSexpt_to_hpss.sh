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
set -u

reten=5  # retention period, 1,2,..., 5 yrs, HPSS
proj="emc-ocean"
expt_name="ufs_datm_mx025"
enmb=""
ENMBS=()
DOUT=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy

# Transfer experiments from scratch dir to HPSS
# HPSS structure:
# /PORTFOLIO/PROJECT/RETENTION
#
usage() {
  echo "Usage: sbatch $0 --enmb 1 20 31 [--reten 5 --proj emc-ocean --expt ufs_datm_mx025]"
  echo "  --enmb  list of experiment numbers to be transfered, e.g. 1 33 15  " 
  echo "  --reten  retention time on HPSS"
  echo "  --proj   project name on HPSS"
  echo "  --ename   experiment name to be transfered, default=${expt_name}"
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
    --reten)
      reten="$2"
      shift 2
      ;;
    --proj)
      proj="$2"
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
  echo "ERROR: --enmb is required"
  usage 
fi

module load hpss

DEXP="${DOUT}/${expt_name}"
DHPSS="/NCEPDEV/${proj}/${reten}year/${USER}/UFS_cice_testruns/${expt_name}"

echo ""
echo "Transferring output from $DEXP to HPSS"
echo ""

cd $DEXP || { echo "Cannot cd to ${DEXP}"; exit 1; }
pwd

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

  echo "Transferring ${dir_expt} --> HPSS: ${DHPSS}"
  # -P creates a dir if does not exist
  htar -P -cvf "${DHPSS}/${dir_expt}.tar" "${dir_expt}" || {
    echo "ERROR: HPSS transfer failed for ${dir_expt}"
    exit 1
  }

  # Mark success:
  {
      echo "Transferred: $(date '+%Y-%m-%d %H:%M:%S')"
      echo "HPSS archive: ${DHPSS}/${dir_expt}.tar"
  } > "${dir_expt}/sent_to_hpss"


done

echo "All Done"

exit 0


#!/bin/bash
#SBATCH --job-name="scpATM"
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

# Copy atmosphere IC from CPC for SFS C192mx025 configuration
# Derived for C192 grid, stored on ursa
usage() {
  echo "Usage: sbatch $0 --rdate 20250701"
  echo "  --rdate    run date YYYYMMDD, e.g. 20250701" 
  exit 1
}

# Load config. variables, paths for ML:
source config_ML.sh


rdate=""
HR=0      # time of forecact IC
HRice=3   # time of CICE restart

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rdate)
      rdate="$2"
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

if [[ -z "$rdate" ]]; then
  echo "ERROR: --rdate is required"
  usage
fi

DATM="${DREST}/atmos"
mkdir -pv $DATM

DURSA="/scratch4/NCEPDEV/global/Yangxing.Zheng/ICs/CPC_land/C192mx025/sfs.${rdate}/00/mem000/model/atmos/input"

cd $DATM || { echo "ERROR: Cannot cd to $DATM"; exit 1; }
pwd
mkdir -pv "${rdate}.00"

cd "${rdate}.00"

for fl in \
  gfs_ctrl.nc \
  gfs_data.tile1.nc gfs_data.tile2.nc gfs_data.tile3.nc gfs_data.tile4.nc \
  gfs_data.tile6.nc \
  sfs_data.tile1.nc sfs_data.tile2.nc sfs_data.tile3.nc \
  sfs_data.tile4.nc sfs_data.tile5.nc sfs_data.tile6.nc; do

  echo "Copying $fl --> ${DATM}/${rdate}.00/"

  scp "Dmitry.Dukhovskoy@udtn-ursa.fairmont.rdhpcs.noaa.gov:${DURSA}/${fl}" . || {
    echo "ERROR: Failed to copy $fl"
    exit 1
  }

done


echo "All Done"

exit 0


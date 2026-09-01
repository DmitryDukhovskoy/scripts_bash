#!/bin/sh
#SBATCH -e logs/err
#SBATCH -o logs/out
#SBATCH --job-name="getGDASatm"
#SBATCH --account=sfs-cpu
#SBATCH --clusters=es
#SBATCH --partition=dtn_f5_f6
#SBATCH --constraint=f6
##SBATCH --qos=normal
#SBATCH --qos=dtn
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --output=logs/%x.o%j
set -u

# Derive gdas atm. surface field
#
usage() {
  echo "Usage: sbatch $0 --rdate 20250701 [--hr 0 6 12 18]"
  echo "  --rdate    run date YYYYMMDD, e.g. 20250701" 
  echo "  --hr     run hour(s): HH or H, e.g. 0 6 12 18 (default) "
  exit 1
}

RUN=retrov17_01_stream4
DROOT=/5year/NCEPDEV/emc-global/emc.glopara/GAEAC6/GFSv17
DWORK=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17
rdate=""
HOURS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rdate)
      rdate="$2"
      shift 2
      ;;
    --hr)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
          HOURS+=("$1")
          shift
      done
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

if [[ ${#HOURS[@]} -eq 0 ]]; then
  HOURS=(0 6 12 18)
fi

for HR in "${HOURS[@]}"; do
  HR=$(printf "%02d" "$HR")

  DHPSS=${DROOT}/${RUN}/${rdate}${HR}
  file_gdas="gdas.t${HR}z.sfc.f000.nc"
  drgdas="gdas.${rdate}/${HR}/model/atmos/history"
  drfl_gdas="${drgdas}/${file_gdas}"

  echo "----------------------------------------"
  echo "Processing hour: ${HR}"
  echo "HPSS directory: $DHPSS"
  echo "Local directory: $DWORK"

  cd $DWORK || { echo "ERROR: Cannot cd to $DWORK"; exit 1; }
  pwd

  htar -xvf "$DHPSS/gdas.tar" "$drfl_gdas"

  # Delete unneeded directories:
  cd "gdas.${rdate}" || { echo "ERROR: Cannot cd to gdas.${rdate}"; exit 1; }
  mv "${HR}/model/atmos/history/${file_gdas}" .

  # Remove now empty directories
  rmdir "${HR}/model/atmos/history" 2>/dev/null
  rmdir "${HR}/model/atmos" 2>/dev/null
  rmdir "${HR}/model" 2>/dev/null
  rmdir "${HR}" 2>/dev/null

  cd $DWORK

done

echo "All Done"

exit 0


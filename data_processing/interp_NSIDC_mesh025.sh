#!/bin/bash
#SBATCH --job-name="interpNSIDC"
#SBATCH --account=sfs-cpu
#SBATCH --clusters=es
#SBATCH --partition=dtn_f5_f6
#SBATCH --constraint=f6
##SBATCH --qos=normal
#SBATCH --qos=dtn
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --error=logs/%x.err%j
#SBATCH --output=logs/%x.o%j
set -euo pipefail

PYPATH=/ncrc/home1/Dmitry.Dukhovskoy/miniconda3
eval "$($PYPATH/bin/conda shell.bash hook)"
conda activate anls

which python
python --version

usage() {
  echo "Usage: sbatch $0 --mm 1 --yr 2025 --regn north"
  echo "  --yr    required year e.g. 2025" 
  echo "  --mm    start month of interpolation 1, ..., 12"
  echo "  --regn  region: north (Arctic) or south (Antarctic)"
  exit 1
}

yr=""
mm=""
regn=""

DPYTH=/ncrc/home1/Dmitry.Dukhovskoy/python/prepare_cice6
fexepy=interp_NSIDC_iconc_mesh025.py

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yr)
      yr="$2"
      shift 2
      ;;
    --mm)
      mm="$2"
      shift 2
      ;;
    --regn)
      regn="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      usage
      ;;
  esac
done

if [[ -z "$yr" ]]; then
  echo "ERROR: --yr is required"
  usage
fi

if [[ -z "$regn" ]]; then
  echo "ERROR: --regn is required"
  usage
fi

if [[ -z "$mm" ]]; then
  echo "ERROR: --mm is required"
  usage
fi

echo ""
echo "Interpolating NSIDC: yr=$yr months: $mm region=$regn"
echo ""

# Launch python to derive daily mean
cd "$DPYTH"
pwd

python "${fexepy}" --regn "$regn" --yr $yr --mm $mm --tmpf 0 || {
  echo "ERROR: Python processing failed for $yr $mm $regn"
  exit 1
}


echo "ALL COMPLETED"
exit 0

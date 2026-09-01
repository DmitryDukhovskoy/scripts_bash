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

PYPATH=/ncrc/home1/Dmitry.Dukhovskoy/miniconda3
eval "$($PYPATH/bin/conda shell.bash hook)"
conda activate anls

which python
python --version

#module load python/3.11

# Derive gdas atm. surface field
# Calc. daily T2m from 6hr GDAS fields
# process every dt day for efficiency
# Delete GDAS after processing
usage() {
  echo "Usage: sbatch $0 --sdate 20250101 --edate 20251231 --dt 3"
  echo "  --sdate  start date YYYYMMDD, e.g. 20250101" 
  echo "  --edate  end   date YYYYMMDD, e.g. 20251231" 
  echo "  --dt     interval (days) between processed days"
  exit 1
}

RUN=""
DWORK=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17
DPYTH=/ncrc/home1/Dmitry.Dukhovskoy/python/ithkn_MLemulator
HOURS=(0 6 12 18)

sdate=""
edate=""
dt=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sdate)
      sdate="$2"
      shift 2
      ;;
    --edate)
      edate="$2"
      shift 2
      ;;
    --dt)
      dt="$2"
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

if [[ -z "$sdate" ]]; then
  echo "ERROR: --sdate is required"
  usage
fi

if [[ -z "$edate" ]]; then
  echo "ERROR: --edate is required"
  usage
fi

if [[ -z "$dt" ]]; then
  echo "ERROR: --dt is required"
  usage
fi

if [[ "$sdate" -gt "$edate" ]]; then
  echo "Start date $sdate > end date $edate"
  exit 1
fi

fexepy=calc_GDAS_T2m_daily.py

DAY="$sdate"
while [[ "$DAY" -le "$edate" ]]; do
  echo "Processing $DAY"

  rdate="$DAY"

  # Find GFSv17 stream
  if [[ "$rdate" -ge 20241201 && "$rdate" -le 20250531 ]]; then
    RUN="retrov17_01_stream3"
    DROOT=/5year/NCEPDEV/emc-global/emc.glopara/WCOSS2/GFSv17
  elif [[ "$rdate" -ge 20250601 && "$rdate" -le 20251130 ]]; then
    RUN="retrov17_01_stream4"
    DROOT=/5year/NCEPDEV/emc-global/emc.glopara/GAEAC6/GFSv17
  elif [[ "$rdate" -ge 20251201 && "$rdate" -le 20260631 ]]; then
    RUN="retrov17_01_realtime"
    DROOT=/5year/NCEPDEV/emc-global/emc.glopara/WCOSS2/GFSv17
  else
    echo "ERROR: No GFSv17 stream defined for $rdate"
    exit 1
  fi

  echo "Using stream: $RUN"

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

    # Check if gdas fields already there
    if [[ -f "gdas.${rdate}/${file_gdas}" ]]; then 
      echo "gdas.${rdate}/${file_gdas} exists, skipping ..."
      continue
    else
      htar -xvf "$DHPSS/gdas.tar" "$drfl_gdas" || {
        echo "ERROR: htar failed for $DHPSS"
        exit 1
      }

      # Delete unneeded directories:
      cd "gdas.${rdate}" || { echo "ERROR: Cannot cd to gdas.${rdate}"; exit 1; }
      mv "${HR}/model/atmos/history/${file_gdas}" .

      # Remove now empty directories
      rmdir "${HR}/model/atmos/history" 2>/dev/null
      rmdir "${HR}/model/atmos" 2>/dev/null
      rmdir "${HR}/model" 2>/dev/null
      rmdir "${HR}" 2>/dev/null
    fi
  done

  cd "$DWORK" || exit 1

  # Launch python to derive daily mean
  cd "$DPYTH"
  pwd
  python "${fexepy}" --rdate "$rdate" --flipN 1  --hr "${HOURS[@]}" || {
    echo "ERROR: Python processing failed for $rdate"
    exit 1
  }

  cd "$DWORK" || exit 1

  # Remove unneeded GDAS:
  echo "Deleting processed $DWORK/gdas.${rdate}"
  rm -rf "$DWORK/gdas.${rdate}"

  DAY=$(date -d "$DAY + $dt days" +%Y%m%d)
done

echo "All Done"

exit 0


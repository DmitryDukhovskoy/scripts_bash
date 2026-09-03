#!/bin/sh
#SBATCH -e logs/err
#SBATCH -o logs/out
#SBATCH --job-name="GDASithkn"
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

# Fetch daily GDAS / SOCA ice fields
# Compute monthly area-mean ivol and ithkn
# Delete all days of the month when finished
# Process 1 month at a time
# Use several jobs to do this in parallel
usage() {
  echo "Usage: sbatch $0 --yr 2025 --mm 7  --dt 3 --regn north"
  echo "  --yr   year of sea ice data, YYYY, e.g. 2025" 
  echo "  --mm   month of sea ice data, e.g. 7" 
  echo "  --dt   interval (days) between processed days, e.g. 5"
  echo "  --regn region to process north / south"
  exit 1
}

RUN=""
DWORK=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17
DPYTH=/ncrc/home1/Dmitry.Dukhovskoy/python/ithkn_MLemulator
PTHYAML=$DPYTH

YR=""
MM=""
dt=""
HR=0      # time of forecact IC
HRice=3   # time of CICE restart
regn=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yr)
      YR="$2"
      shift 2
      ;;
    --mm)
      MM="$2"
      shift 2
      ;;
    --dt)
      dt="$2"
      shift 2
      ;;
    --regn)
      regn="$2"
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

if [[ -z "$YR" ]]; then
  echo "ERROR: --sdate is required"
  usage
fi

if [[ -z "$MM" ]]; then
  echo "ERROR: --edate is required"
  usage
fi

if [[ -z "$dt" ]]; then
  echo "ERROR: --dt is required"
  usage
fi

if [[ "$MM" -gt 12 || $MM -lt 1 ]]; then
  echo "Month value is incorrect: $MM"
  exit 1
fi

HR=$(printf "%02d" "$HR")
HRice=$(printf "%02d" "$HRice")
MM=$(printf "%02d" "$MM")
mkdir -p  "${DWORK}/tmp_hpss"  # dump directory
fexepy=calc_mean_ithkn_SOCAcice6.py

rdate="${YR}${MM}01"
edate=$(date -d "${YR}-${MM}-01 +1 month -1 day" +%Y%m%d)

# Output dir from python script to dump daily values
# pthprd  = os.path.join(pths_ml["PRED"]["pthprd"],'tmp')  
pthprd=$(awk '
  /^PRED:[[:space:]]*$/ { in_pred=1; next }
  in_pred && /^[^[:space:]#]/ { in_pred=0 }
  in_pred && /^[[:space:]]+pthprd:[[:space:]]*/ {
      sub(/^[[:space:]]+pthprd:[[:space:]]*/, "")
      gsub(/"/, "")
      print
      exit
  }
  ' $PTHYAML/paths_ML.yaml)
if [[ -z "$pthprd" ]]; then
  echo "ERROR: Could not find PRED.pthprd in paths_ML.yaml" >&2
  exit 1
fi

pthprd="${pthprd}/tmp"

while [[ "$rdate" -le "$edate" ]]; do
  echo "Processing $rdate"

  # Check if this day has been already processed
  fltmp="cice6_mean_ivol_ithkn_${rdate}_${regn}.npz"
  if [[ -f "$pthprd/$fltmp" ]]; then
    echo "$pthprd/$fltmp exist, skipping ..."

  else

    # Find GFSv17 stream
    if [[ "$rdate" -ge 20241201 && "$rdate" -le 20250531 ]]; then
      RUN="retrov17_01_stream3"
      DROOT=/5year/NCEPDEV/emc-global/emc.glopara/WCOSS2/GFSv17
    elif [[ "$rdate" -ge 20250601 && "$rdate" -le 20251130 ]]; then
      RUN="retrov17_01_stream4"
      DROOT=/5year/NCEPDEV/emc-global/emc.glopara/GAEAC6/GFSv17
    elif [[ "$rdate" -ge 20251201 && "$rdate" -le 20260630 ]]; then
      RUN="retrov17_01_realtime"
      DROOT=/5year/NCEPDEV/emc-global/emc.glopara/WCOSS2/GFSv17
    else
      echo "ERROR: No GFSv17 stream defined for $rdate"
      exit 1
    fi

    echo "Using stream: $RUN"
    DHPSS=${DROOT}/${RUN}/${rdate}${HR}
    file_cice="${rdate}.${HRice}0000.cice_model.res.nc"
    drcice="gdas.${rdate}/${HR}/model/ice/restart"
    drfl_cice="${drcice}/${file_cice}"

    echo "----------------------------------------"
    echo "Processing hour: ${HR}"
    echo "HPSS directory: $DHPSS"
    echo "Local directory: $DWORK"

    cd $DWORK/tmp_hpss || { echo "ERROR: Cannot cd to $DWORK/tmp_hpss"; exit 1; }
    pwd

    #htar -xvf "$DHPSS/gdasice_restart.tar" "$drfl_cice" || {
    #  echo "ERROR: htar extraction failed for $rdate"
    #  exit 1
    #}
    
    # Allow for some missing / corrupted files on HPSS:
    # Delete temporary dir if failed to tar from HPSS
    # Advance time
    htar -xvf "$DHPSS/gdasice_restart.tar" "$drfl_cice" || {
      echo "WARNING: htar extraction failed for $rdate; skipping"
      rm -rf "gdas.${rdate}"
      rdate=$(date -d "$rdate + $dt days" +%Y%m%d)
      continue
    }

    # Delete unneeded directories:
    cd "gdas.${rdate}" || { echo "ERROR: Cannot cd to gdas.${rdate}"; exit 1; }

    mv "${HR}/model/ice/restart/${file_cice}" . || {
      echo "ERROR: Cannot move ${file_cice}"
      exit 1
    }

    # Remove now empty directories
    rmdir "${HR}/model/ice/restart" 2>/dev/null
    rmdir "${HR}/model/ice" 2>/dev/null
    rmdir "${HR}/model" 2>/dev/null
    rmdir "${HR}" 2>/dev/null

    # rename to distinguish from other gdas fields
    cd ..
    mv gdas.${rdate} ${DWORK}/ice.${rdate}

    cd "$DWORK" || exit 1

    # Launch python to derive daily mean
    cd "$DPYTH"
    pwd
    python "${fexepy}" --rdate "$rdate" --regn "$regn" || {
      echo "ERROR: Python processing failed for $rdate"
      exit 1
    }

    cd "$DWORK" || exit 1

    # Remove unneeded GDAS:
    echo "Deleting processed $DWORK/gdas.${rdate}"
    rm -rf "$DWORK/ice.${rdate}"

  fi

  rdate=$(date -d "$rdate + $dt days" +%Y%m%d)
done

# Combine temporary daily ithkn / ivol --> monthly file
cd "$DPYTH"
python combine_mean_ithkn_SOCAcice6_monthly.py --regn "$regn" --yr $YR  --mm $MM || {
      echo "ERROR: Python combining daily --> monthly failed $YR / $MM"
      exit 1
    }

# Delete unneeded daily files
cd "$DWORK" || exit 1
echo "Deleting daily fields for $YR / $MM"
rm "${pthprd}/cice6_mean_ivol_ithkn_${YR}${MM}*_${regn}.npz"

echo "All Done"

exit 0


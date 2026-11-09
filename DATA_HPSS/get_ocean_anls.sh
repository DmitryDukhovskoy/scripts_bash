#!/bin/bash
#SBATCH --job-name="getSOCAocean"
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
set -u

# Derive MOM6 analysis: 6hr IAU, use -6hr field
#  Use analysis for SST predictor
#  Do not use these fields as MOM6 restarts to update SST
#  Use MOM restart fields instead saved under gdasocean_restart.tar
#  Not available for every day
#  Use: get_ocean_restart.sh 
usage() {
  echo "Usage: sbatch $0 --rdate 20250701"
  echo "  --rdate    run date YYYYMMDD, e.g. 20250701" 
  exit 1
}

# Load config. variables, paths for ML:
source config_ML.sh

rdate=""
HR=0        # time of forecast IC
Tanls=6     # Time of IAU, hrs

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rdate)
      if [[ -z "${2:-}" ]]; then 
        echo "ERROR: --rdate requires a value" 
        usage 
      fi
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

mkdir -pv ${DWORK}/tmp_hpss

# Find date of the previous day when mom analysis started
# IAU start date and IAU start hour = -6hr from forecast run
#adate=$(date -d "$rdate - 1 days" +%Y%m%d)
adate=$(date -d "$rdate - 1 day" +%Y%m%d) || { 
  echo "ERROR: Invalid date: $rdate" 
  exit 1 
}
HRa=$((10#$HR + 24 - Tanls))              # IAU start hour
HRa=$((HRa % 24))
HRa=$(printf "%02d" "$HRa")

# Find GFSv17 stream
if ! find_gfs_stream "${rdate}"; then
  exit 1
fi

# RUN and DROOT are now available:
echo "Stream: $RUN"
echo "DROOT: $DROOT"

# Format hours
HR=$(printf "%02d" "$HR")
Fhr=$(printf "%03d" "$Tanls")
DHPSS=${DROOT}/${RUN}/${adate}${HRa}
file_ocean="gdas.t${HRa}z.inst.f${Fhr}.nc"
drocean="gdas.${adate}/${HRa}/model/ocean/history"
drfl_ocean="${drocean}/${file_ocean}"

echo "----------------------------------------"
echo "Init date:       $rdate" 
echo "IAU date:        $adate" 
echo "IAU start hour:  $HRa" 
echo "Using stream:    $RUN" 
echo "HPSS directory:  $DHPSS" 
echo "Local directory: $DWORK" 
echo "Ocean file:      $file_ocean" 
echo "----------------------------------------"

cd $DWORK/tmp_hpss || { echo "ERROR: Cannot cd to $DWORK/tmp_hpss"; exit 1; }
pwd

htar -xvf "$DHPSS/gdasocean.tar" "$drfl_ocean" || { 
  echo "ERROR: htar extraction failed"
  exit 1
}

# Delete unneeded directories:
cd "gdas.${adate}" || { echo "ERROR: Cannot cd to gdas.${adate}"; exit 1; }
mv "${HRa}/model/ocean/history/${file_ocean}" .

# Remove now empty directories
rmdir "${HRa}/model/ocean/history" 2>/dev/null
rmdir "${HRa}/model/ocean" 2>/dev/null
rmdir "${HRa}/model" 2>/dev/null
rmdir "${HRa}" 2>/dev/null

# rename to distinguish from other gdas fields
cd ..
mv gdas.${adate} ${DWORK}/ocean.${adate} || { 
  echo "ERROR: Cannot rename gdas.${adate}" 
  exit 1
}

cd $DWORK


echo "All Done"

exit 0


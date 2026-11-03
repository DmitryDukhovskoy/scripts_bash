#!/bin/bash
#SBATCH --job-name="getMOM6restart"
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
#  Do not use these fields as MOM6 restarts if SST is modified - model blows up
#  Use MOM restart fields instead saved under gdasocean_restart.tar
#  Not available for every day
#  Use: get_ocean_restart.sh 
usage() {
  echo "Usage: sbatch $0 --rdate 20250701"
  echo "  --rdate   date when ocean restart is available YYYYMMDD, e.g. 20250701" 
  exit 1
}

# Load config. variables, paths for ML:
source config_ML.sh

rdate=""
HR=18        # time when restart is dumped

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

adate=$rdate

# Find GFSv17 stream
if ! find_gfs_stream "${rdate}"; then
  exit 1
fi

# RUN and DROOT are now available:
echo "Stream: $RUN"
echo "DROOT: $DROOT"

# Format hours
HR=$(printf "%02d" "$HR")
DHPSS=${DROOT}/${RUN}/${adate}${HR}
file_ocean="${adate}.210000.MOM.res"
drocean="gdas.${adate}/${HR}/model/ocean/restart"
drfl_ocean="${drocean}/${file_ocean}"

echo "----------------------------------------"
echo "Init date:       $rdate" 
echo "Anls date:       $adate" 
echo "Using stream:    $RUN" 
echo "HPSS directory:  $DHPSS" 
echo "Local directory: $DWORK" 
echo "MOM rest file:   $file_ocean" 
echo "----------------------------------------"

cd $DWORK/tmp_hpss || { echo "ERROR: Cannot cd to $DWORK/tmp_hpss"; exit 1; }
pwd

htar -xvf "$DHPSS/gdasocean_restart.tar" || { 
  echo "ERROR: htar extraction failed"
  exit 1
}

# Delete unneeded directories:
cd "gdas.${adate}" || { echo "ERROR: Cannot cd to gdas.${adate}"; exit 1; }
mv "${HR}/model/ocean/restart/${file_ocean}*.nc" . || {
  echo "ERROR: could not move ${file_ocean}*nc files from tmp dir"
  exit 1
}

rm ${HR}/model/ocean/restart/*

# Remove now empty directories
rmdir "${HR}/model/ocean/history" 2>/dev/null
rmdir "${HR}/model/ocean" 2>/dev/null
rmdir "${HR}/model" 2>/dev/null
rmdir "${HR}" 2>/dev/null

# rename to distinguish from other gdas fields
cd ..
mv gdas.${adate} ${DWORK}/ocean.${adate} || { 
  echo "ERROR: Cannot rename gdas.${adate}" 
  exit 1
}

cd $DWORK


echo "All Done"

exit 0


#!/bin/sh
#SBATCH -e logs/err
#SBATCH -o logs/out
#SBATCH --job-name="getMOMres"
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

# Derive SOCA ocean MOM6 restart files
# MOM6 restart are saved 6hr before the run 
# and not every day (?), e.g. retrov17_01_stream4/2025062918/gdasocean_restart.tar,
# next one: retrov17_01_stream4/2025070318/gdasocean_restart.tar
usage() {
  echo "Usage: sbatch $0 --rdate 20250701"
  echo "  --rdate    run date YYYYMMDD, e.g. 20250701" 
  echo "  --dd       delta days to search for ocean restart around rdate, default=3"
  exit 1
}

find_gfs_stream() {
  local rdate="$1"

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
    echo "No GFSv17 stream defined for $rdate"
    return 1
  fi
}

RUN=""
DROOT=""
DWORK=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17
rdateR=""
HR=18      # time of cycle where MOM6 restart should beC
HRocn=21   # actual time of MOM6 restart, e.g. 20250629.210000.MOM.res.nc
dday=3    # search for restarts +/- dday from the desired date=rdate

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rdate)
      [[ $# -ge 2 ]] || { echo "ERROR: --rdate requires an argument"; usage; }
      rdateR="$2"
      shift 2
      ;;
    --dd)
      [[ $# -ge 2 ]] || { echo "ERROR: --dd requires an argument"; usage; }
      dday="$2"
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

if [[ -z "$rdateR" ]]; then
  echo "ERROR: --rdate is required"
  usage
fi

mkdir -pv ${DWORK}/tmp_hpss


HR=$(printf "%02d" "$HR")
HRocn=$(printf "%02d" "$HRocn")

# Start searching:
dt=0
htar_found=0
# Step 1 day back to match requested start date, as MOM6 analysis is 6hr earlier:
rdateS=$(date -d "$rdateR - 1 days" +%Y%m%d)
for ((dt=0; dt<=dday; dt++)); do
  for sign in 1 -1; do

      offset=$((sign*dt))

      # avoid checking 0 twice
      if ((dt==0 && sign==1)); then
          continue
      fi

      rdate=$(date -d "$rdateS $offset days" +%Y%m%d)
      find_gfs_stream "$rdate" || {
        echo "Could not find GFSv17 stream for $rdate"
        exit 1
      }

      DHPSS=${DROOT}/${RUN}/${rdate}${HR}

      # Check if MOM restart is there:
      if htar -tvf "$DHPSS/gdasocean_restart.tar" >/dev/null 2>&1; then
        echo "----------------------------------------"
        echo "Using stream: $RUN"
        echo "Hindcast hour: ${HR}"
        echo "HPSS directory: $DHPSS"
        echo "Local directory: $DWORK"

        cd $DWORK/tmp_hpss || { echo "ERROR: Cannot cd to $DWORK/tmp_hpss"; exit 1; }

        tarlist=$(htar -tvf "$DHPSS/gdasocean_restart.tar" \
                | awk '/MOM\.res/ {print $NF}')

        for drfl_ocean in $tarlist
        do
          echo "Extracting $drfl_ocean"
          htar -xvf "$DHPSS/gdasocean_restart.tar" "$drfl_ocean" || {
          echo "ERROR: Failed to extract $drfl_ocean"
          exit 1
          }
        done

        # Delete unneeded directories:
        cd "gdas.${rdate}" || { echo "ERROR: Cannot cd to gdas.${rdate}"; exit 1; }
        pwd

        mv ${HR}/model/ocean/restart/${rdate}.*MOM.res*nc . || {
          echo "ERROR: Cannot move MOM restarts to a new dir"
          exit 1
        }

        # Remove now empty directories
        rmdir "${HR}/model/ocean/restart" 2>/dev/null
        rmdir "${HR}/model/ocean" 2>/dev/null
        rmdir "${HR}/model" 2>/dev/null
        rmdir "${HR}" 2>/dev/null

        # rename to distinguish from other gdas fields
        cd ..
        mv gdas.${rdate} ${DWORK}/ocean_res.${rdate}

        cd $DWORK || exit 1

        htar_found=1
        break
      fi
  done

  [[ $htar_found -eq 1 ]] && break
done

cd $DWORK

if [[ $htar_found -eq 0 ]]; then
  echo "Could not find htar MOM restart for ${rdateR}"
else
  echo "All Done"
fi

exit 0


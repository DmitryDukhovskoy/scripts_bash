#!/bin/sh
#SBATCH -e logs/err
#SBATCH -o logs/out
#SBATCH --job-name="getSOCAice"
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

# Derive SOCA ice incorporated into restart file
#
usage() {
  echo "Usage: sbatch $0 --rdate 20250701"
  echo "  --rdate    run date YYYYMMDD, e.g. 20250701" 
  exit 1
}

RUN=retrov17_01_stream4
DROOT=/5year/NCEPDEV/emc-global/emc.glopara/GAEAC6/GFSv17
DWORK=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17
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

mkdir -pv ${DWORK}/tmp_hpss

HR=$(printf "%02d" "$HR")
HRice=$(printf "%02d" "$HRice")
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

htar -xvf "$DHPSS/gdasice_restart.tar" "$drfl_cice"

# Delete unneeded directories:
cd "gdas.${rdate}" || { echo "ERROR: Cannot cd to gdas.${rdate}"; exit 1; }
mv "${HR}/model/ice/restart/${file_cice}" .

# Remove now empty directories
rmdir "${HR}/model/ice/restart" 2>/dev/null
rmdir "${HR}/model/ice" 2>/dev/null
rmdir "${HR}/model" 2>/dev/null
rmdir "${HR}" 2>/dev/null

# rename to distinguish from other gdas fields
cd ..
mv gdas.${rdate} ${DWORK}/ice.${rdate}

cd $DWORK


echo "All Done"

exit 0


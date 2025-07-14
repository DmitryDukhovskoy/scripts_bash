#!/bin/bash 
# Link and rename ERA5 forcing files
set -u

YR=2001
#DIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/NEP_datasets/ERA5_corrected/${YR}
DIR=/gpfs/f6/ira-cefi/world-shared/NEP_input/NEP_era5
#DRUN=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEPbgc_nudged_hindcast01.o135497833/INPUT
#DIR=/gpfs/f5/cefi/world-shared/NEP_era5
DRUN=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/work/NEP_irlx_test/INPUT
#sfx='cp120hrs_'
#sfx='cp121Bhrs_'
sfx=''

usage() {
  echo "Usage: $0 --year 1994"
  echo "  --year  year of the forcing fields"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --year)
      YR=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done


if [[ ! -d "$DIR" ]]; then
  echo "Error: Source directory $DIR does not exist."
  exit 1
fi

if [[ ! -d "$DRUN" ]]; then
  echo "Error: Target directory $DRUN does not exist."
  exit 1
fi

cd "$DRUN" || { echo "Error: Cannot change to directory $DRUN"; exit 1; }
pwd

for prfx in lp msl sf sphum ssrd strd t2m u10 v10; do
#  flera=ERA5_${prfx}_${YR}_cp001hrs_padded.nc
  flera=ERA5_${prfx}_${YR}_${sfx}padded.nc
  flfrc=ERA5_${prfx}_${YR}_padded.nc
  /bin/rm -f ${flfrc}
  echo "linking $DIR/$flera --> $flfrc"
  if [ -f $DIR/$flera ]; then
    ln -sf $DIR/$flera $flfrc
  else
    echo "Not found $DIR/$flera"
    exit 1
  fi
done

exit 0


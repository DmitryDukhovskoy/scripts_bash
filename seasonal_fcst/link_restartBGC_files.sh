#!/bin/bash 
# Link and rename BGC files
set -u

rest_date=20010101
DIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/restart_bgc/restart_hindcast/restdate_${rest_date}
DRUN=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_irlx_test/INPUT


function set_link {
  local DRST=$1
  local flrest=$2

  if [[ -f $flrest ]]; then
    echo "linking $DRST/$flrest"
    ln -sf $DRST/$flrest .
  else
    echo "Missing $DRST/$flrest"
    touch ${flrest}_MISSING
  fi

}

if [[ ! -d "$DIR" ]]; then
  echo "Error: Source directory $DIR does not exist."
  exit 1
fi

if [[ ! -d "$DRUN" ]]; then
  echo "Error: Target directory $DRUN does not exist."
  exit 1
fi

cd "$DRUN" || { echo "Error: Cannot change to directory $DRUN"; exit 1; }

set_link $DIR coupler.res

for ff in ice_cobalt ice_model ocean_cobalt_airsea_flux ; do
  fll=${ff}.res.nc
  set_link $DIR ${fll}
done

for fll in ${DIR}/MOM.res*nc; do
  if [[ -f "$fll" ]]; then
    echo "linking $fll"
    ln -sf "$fll" .
  fi
done
  

exit 0


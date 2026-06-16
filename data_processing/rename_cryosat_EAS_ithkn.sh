#!/bin/bash
#
# Rename files downloaded from EAS 
# https://e.pcloud.link/publink/show?code=kZF5QqZFPGD9YUzvRjfBD0ggwNmOFopMo1V
#
set -u

DIRD=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/CryoSat_arctic_ice_snow_thkn/monthly

cd "$DIRD" || exit 1

for f in CS_OFFL_SIR_TDP_SD_ARCTIC_*.nc; do
  # Extract YYYYMM from the first date block
  yyyymm=$(echo "$f" | sed -E 's|.*_([0-9]{6})[0-9]{2}T.*|\1|')

  newname="Cryosat_arctic_icethkn_${yyyymm}.nc"

  echo "Moving $f --> $newname"
  mv "$f" "$newname"
done

exit 0


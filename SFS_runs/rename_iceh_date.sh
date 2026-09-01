#!/bin/bash
# shift 1 day in names
set -u

WD=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/sfs_C192mx025_cice_test/expt13/cice6

cd $WD
pwd

for f in iceh.2025-07-*.nc; do
	date=$(basename "$f" .nc | cut -d. -f2)
	newdate=$(date -d "$date - 1 day" +%Y-%m-%d)
  echo mv "$f" "iceh.${newdate}.nc"
  mv "$f" "iceh.${newdate}.nc"
done

f=iceh.2025-08-01.nc
newdate=2025-07-31
echo mv "$f" "iceh.${newdate}.nc"
mv "$f" "iceh.${newdate}.nc"


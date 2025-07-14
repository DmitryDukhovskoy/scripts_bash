#!/bin/bash 
# Merge 2yrs of Netcdf ERA files
set -u

DIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/NEP_datasets/ERA5_2yrs
YR1=1993
YR2=1994

cd $DIR
/bin/rm -f temp1.nc
for fld in msl t2m sphum u10 v10 strd ssrd lp sf; do
  echo "Processing ${fld}"
  file1=ERA5_${fld}_${YR1}_padded
  file2=ERA5_${fld}_${YR2}_padded
  #Use ncks to slice all but the last record in the 1 st file:
  #-d time,0,-2 selects all records from index 0 to second-to-last (-2).
  ncks -d time,0,-2 ${file1}.nc temp1.nc

  merged=ERA5_${fld}_${YR1}_${YR2}_padded
  echo "merging ${file1}.nc + ${file2}.nc ---> ${merged}.nc ..."
  ncrcat temp1.nc ${file2}.nc -o ${merged}.nc
  /bin/rm -f temp1.nc
done

exit 0


#!/bin/bash 
# Merge 2yrs of Netcdf ERA files
set -u

DIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/NEP_datasets/GLORYS_2yrs
YR1=1993
YR2=1994

cd $DIR
/bin/rm -f temp1.nc
file1=glorys_monthly_NEP_sponge_${YR1}_clim.nc
file2=glorys_monthly_NEP_sponge_${YR2}_clim.nc
#Use ncks to slice all but the last record in the 1 st file:
#-d time,0,-2 selects all records from index 0 to third-to-last (-3) - skipp last 3 records
echo "Slicing 2 last records from ${file1}"
ncks -d time,0,-3 ${file1} temp1.nc

merged=glorys_monthly_NEP_sponge_${YR1}_${YR2}_clim.nc
echo "merging ${file1} + ${file2} ---> ${merged} ..."
ncrcat temp1.nc ${file2} -o ${merged}
/bin/rm -f temp1.nc

exit 0


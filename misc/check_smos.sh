#!/bin/bash 
# check netcdf
export DR=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/SMOS

cd $DR
ls -l
for sdr in $(ls -d -1 2023*)
do
  cd ${DR}/${sdr}/wtxtbul/satSSS/SMOS
  pwd
  for fll in $(ls -1 SM_*.nc)
  do 
    ncdump -h $fll | head -1
 
  done
done 

exit 0


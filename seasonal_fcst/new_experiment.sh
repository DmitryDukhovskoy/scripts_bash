#!/bin/sh 
# 
# Quick setup of a new experiment to run test simulations
# using existing old run directory
# !!!!
# Careful: some old files will be deleted in the new experiment dir if it exists !!!
# !!!!
#

set -u

export DROOT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work
export EXPTOLD=NEP_isponge_test
export EXPTNEW=NEP_seasfcst_test

DOLD=${DROOT}/${EXPTOLD}
cd $DROOT
pwd
mkdir -pv $EXPTNEW/INPUT
mkdir -pv $EXPTNEW/RESTART
mkdir -pv $EXPTNEW/log

cd $DROOT/$EXPTNEW
/bin/cp ${DOLD}/*.sh .

for fl in data_table diag_table field_table input.nml
do
  /bin/cp ${DOLD}/${fl} .
done

cd INPUT
/bin/cp ${DOLD}/INPUT/atmos_mosaic*nc .
/bin/cp ${DOLD}/INPUT/land_mosaic_tile*nc .
/bin/cp ${DOLD}/INPUT/mask_table.* .
/bin/cp ${DOLD}/INPUT/mask_table.* .
/bin/cp ${DOLD}/INPUT/ocean_*.nc .
/bin/cp ${DOLD}/INPUT/SIS_* .


for fl in coupler.res depflux_total.mean.1860.nc diag_dz.nc grid_spec.nc land_mask.nc MOM_input MOM_override \
          MOM_layout mosaic.nc vgrid_75_2m.nc
do
  /bin/cp -f ${DOLD}/INPUT/${fl} .
done 

# Copy symbolic links:
for fl in $( ls -l $DOLD/* | grep '\->' | tr -s ' ' | cut -d' ' -f9 ); do
  /bin/cp -P ${DOLD}/INPUT/$fl . 
done
ls -l

exit 0


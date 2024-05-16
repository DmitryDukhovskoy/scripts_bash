#! /bin/bash -x
#
# Prepare a new simulation with MOM6-SIS2
# regional application
# 
# First, modify model_configure start date and duration of the run 
# nhours_fcst 
# nhours_fcst have to be divisible by 24 giving integer N. of days!
#
# Prepare data/restart pointers & restart files 
# for a new run starting on YYYY MM DD HH 
# Start time/date is read from model_configure 
# 
# Dmitry Dukhovskoy, NOAA/OAR/PSL 
#

set -u

export regn=NEP
export expt=NEP_test
export DSRC=${HOME}/scripts/MOM6_regional
export DSCR=/gpfs/f5/cefi/scratch/${USER}
export RDIR=${DSCR}/${expt}
export RDATA=${RDIR}/${regn}_datasets
export WD=$RDIR
export RD=$WD/RESTART
export DINP=$WD/INPUT
export ATMF=ERA5
export YR=1993

mkdir -pv $RD
mkdir -pv $DINP

export DEXE=/ncrc/home1/${USER}/CEFI_MOM6/builds/build/gaea-ncrc5.intel23/ocean_ice/repro/
export HEXE=MOM6SIS2
cd $RDIR
touch $HEXE
/bin/rm -f $HEXE
/bin/cp -f $DEXE/$HEXE .

# Create links
cd $DINP
pwd
# atmos_mosaic_tile1Xland_mosaic_tile1.nc?
# atmos_mosaic_tile1Xocean_mosaic_tile1.nc ?

/bin/ln -sf $RDATA/obcs/bgc/bgc_cobalt.nc .
/bin/ln -sf $RDATA/obcs/bgc/bgc_esper.nc . 
/bin/ln -sf $RDATA/obcs/bgc/bgc_woa.nc .
/bin/ln -sf $RDATA/obcs/diags/diag_dz.nc .

for sfx in lp msl sf sphum ssrd strd t2m u10 v10; do
  /bin/ln -sf $RDATA/$ATMF/${ATMF}_${sfx}_${YR}_padded.nc .
done

/bin/ln -sf $RDATA/runoff/glofas/glofas_hill_dis_runoff_new_${YR}.nc .

/bin/cp -f $RDATA/mask_tables/mask_table.* .

# IC:
/bin/ln -sf $RDATA/inits/glorys/nep_new_init_1993-01-01_glorys.nc .

# Input config/ parameter files:
IMO=20
JMO=50
for sfx in input layout override; do
  /bin/cp -f $RDIR/INPUT_config/MOM_${sfx} .
done


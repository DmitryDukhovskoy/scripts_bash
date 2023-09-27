#!/bin/sh -x
#
# Prepare empty run directory for MOM6-CICE6
set -u

export BN=/scratch1/NCEPDEV/stmp2/${USER}
export expt=glb0.08_frun
export res=0.08
export WD=${BN}/mom6_cice6/${expt}
export WOLD=${BN}/FV3_RT/test_ciceC/datm_cdeps_mx025_gefs # Old run

mkdir -pv ${WD}
cd $WD
pwd

mkdir -pv DATM_INPUT
mkdir -pv history
mkdir -pv MOM6_OUTPUT
mkdir -pv INPUT/MOM_input
mkdir -pv INPUT/MOM_override
mkdir -pv RESTART
mkdir -pv bkp_log

/bin/cp -f $WOLD/*.sh .
/bin/cp -f *.lua .

export cice_res=cice_model.res.nc
export grid_cice=grid_cice_NEMS_mx025.nc
export kmtu_cice=kmtu_cice_NEMS_mx025.nc
export mesh_elmnt=mesh.mx025.nc

for fl in diag_table datm_in datm.streams fd_nems.yaml model_configure \
          nems.configure rpointer.atm rpointer.cpl ${cice_res} ${grid_cice} \
          ${kmtu_cice} ${mesh_elmnt}
do 
  /bin/cp -f $fl .
done

export atm_mesh=gefs_mesh.nc
cd $WD/DATM_INPUT
cp $WOLD/DATM_INPUT/$atm_mesh .

cd $WD/INPUT
cp $WO/INPUT/*.nc .


 

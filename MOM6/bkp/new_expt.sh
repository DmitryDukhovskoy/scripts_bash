#!/bin/sh -x
#
# Prepare empty run directory for MOM6-CICE6
# for new experiment
set -u

export BN=/scratch1/NCEPDEV/stmp2/${USER}/MOM6_run
export Enew=003
export Eold=002
export WD=${BN}/008mom6cice6_${Enew}
export WOLD=${BN}/008mom6cice6_${Eold}
export SCR=/home/Dmitry.Dukhovskoy/scripts/MOM6

mkdir -pv ${WD}
cd $WD
pwd

mkdir -pv DATM_INPUT
mkdir -pv history
mkdir -pv MOM6_OUTPUT
mkdir -pv INPUT
mkdir -pv RESTART
mkdir -pv log
mkdir -pv modulefiles

#/bin/cp -f /home/Dmitry.Dukhovskoy/scripts/MOM6/*.sh .
/bin/cp -f *.lua .

export grid_cice=grid_cice_NEMS_mx008.nc
export kmtu_cice=kmtu_cice_NEMS_mx008.nc
export mesh_elmnt=mesh.mx008.nc

for fl in data_table datm_in datm.streams diag_table fd_nems.yaml \
          ${grid_cice} ice_in ice.restart_file input.nml ${kmtu_cice} \
          ${mesh_elmnt} model_configure module-setup.sh \
          nems.configure rpointer.atm rpointer.cpl \
          run_cycles.txt ufs_common_debug.lua 
do 
  /bin/cp -f $WOLD/$fl .
done

export atm_mesh=gefs_mesh.nc
cd $WD/DATM_INPUT
/bin/cp $WOLD/DATM_INPUT/$atm_mesh .

cd $WD/INPUT
/bin/cp $WOLD/INPUT/*.nc .
/bin/rm -f MOM.res*nc
cd $WD

/bin/cp $SCR/arange_*.sh .
/bin/cp $SCR/check_*.sh .
for fscr in clean.sh continue_run.sh list_cycles.sh prepare_run.sh \
            rename_restart.sh run_next_cycle.sh sub_mom6cice.sh \
            wipe.sh
do
  /bin/cp $SCR/$fscr .
done

 

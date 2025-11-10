#!/bin/bash
#
# Prepare run directory for UFS data atm (forced by atm fields) coupled MOM6-CICE6
# for new experiment
set -u

SCR=/home/Dmitry.Dukhovskoy/scripts/MOM6
DSCR="/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RT_RUNDIRS/$USER"
RUNOLD="${DSCR}/FV3_RT/rt_mx025_2175151/datm_cdeps_mx025_gefs_intel"
RUNNEW="${DSCR}/FV3_RT/rt_mx025_2175151/ufs_datm_mx025_expt01"

# Specify path, names of the executables used in this run
DEXE=/gpfs/f6/sfs-emc/scratch/Dmitry.Dukhovskoy/CODE/mom6_cice6_datm/tests
UFSEXE=fv3_datm_cdeps_intel.exe  # full name after compilation
HEXE=fv3.exe                     # short name of the executable
ATMF=GEFS
atm_mesh=cfsr_mesh.nc

mkdir -pv ${RUNNEW}
cd $RUNNEW || {echo "Could not cd to $RUNNEW"; exit 1}
pwd

#mkdir -pv DATM_INPUT
mkdir -pv history
mkdir -pv MOM6_OUTPUT
mkdir -pv INPUT
mkdir -pv RESTART
mkdir -pv log
mkdir -pv modulefiles
#mkdir -pv config

#/bin/cp -f /home/Dmitry.Dukhovskoy/scripts/MOM6/*.sh .
/bin/cp -f ${RUNOLD}/modulefiles/* modulefiles/.

/bin/cp $SCR/../awk_utils/dates.awk .

export grid_cice=grid_cice_NEMS_mx025.nc
export kmtu_cice=kmtu_cice_NEMS_mx025.nc
export mesh_elmnt=mesh.mx025.nc

for fl in data_table datm_in datm.streams diag_table fd_nems.yaml \
          ${grid_cice} ice_in ice.restart_file input.nml ${kmtu_cice} \
          ${mesh_elmnt} model_configure module-setup.sh \
          nems.configure rpointer.atm rpointer.cpl ufs_common_debug.lua 
do 
  /bin/cp -f $RUNOLD/$fl .
done

#cd $RUNNEW/DATM_INPUT
/bin/cp $RUNOLD/DATM_INPUT/$atm_mesh .

cd $RUNNEW/INPUT
/bin/cp $RUNOLD/INPUT/*.nc .
/bin/cp $RUNOLD/MOM_{input,layout,override} .
cd $RUNNEW

/bin/cp $SCR/arrange_*.sh .
/bin/cp $SCR/check_*.sh .
for fscr in clean.sh continue_run.sh list_cycles.sh prepare_run.sh \
            rename_restart.sh run_next_cycle.sh sub_mom6cice.sh \
            wipe.sh
do
  /bin/cp $SCR/$fscr .
done

/bin/ln -sf arrange_mom_restart_v2.sh arrange_mom_restart.sh
for FLL in arrange_cice_output.sh arrange_mom_output.sh 
do
  touch tmp.sh
  /bin/rm -f tmp.sh
  cp $FLL tmp.sh
  sed -e "s|export expt=.*|export expt=${expt}|" tmp.sh > $FLL
  /bin/rm tmp.sh
done

# Change executable names:
for FLL in prepare_run.sh continue_run.sh 
do
  touch tmp.sh
  /bin/rm -f tmp.sh
  cp $FLL tmp.sh
  sed -e "s|export DEXE=.*|export DEXE=${DEXE}|" \
      -e "s|export ATMF=.*|export ATMF=${ATMF}|"\
      -e "s|export UFSEXE=.*|export UFSEXE=${UFSEXE}|"\
      -e "s|export HEXE=.*|export HEXE=${HEXE}|" tmp.sh > $FLL
  chmod 750 $FLL
  /bin/rm tmp.sh
done


sed -i "s|export HEXE=.*|export HEXE=${HEXE}|" sub_mom6cice.sh


# Keep all model config files in 1 dir:
cd ${RUNNEW}
for fll in data_table datm_in datm.streams diag_table ice_in input.nml \
           model_configure nems.configure
do
  /bin/mv $fll config/.
  /bin/ln -sf config/${fll} .
done



echo "All done"

exit 0 

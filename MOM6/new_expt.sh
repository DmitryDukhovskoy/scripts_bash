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
# Specify path, names of the executables used in this run
export DEXE=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/MOM6/ufs-weather-model/tests
export UFSEXE=fv3_datm_cdeps_intel.exe  # full name after compilation
export HEXE=fv3_001.exe                 # short name of the executable
export ATMF=CFSR

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
/bin/cp -f ${WOLD}/modulefiles/* modulefiles/.

/bin/cp $SCR/../awk_utils/dates.awk .

export grid_cice=grid_cice_NEMS_mx008.nc
export kmtu_cice=kmtu_cice_NEMS_mx008.nc
export mesh_elmnt=mesh.mx008.nc

for fl in data_table datm_in datm.streams diag_table fd_nems.yaml \
          ${grid_cice} ice_in ice.restart_file input.nml ${kmtu_cice} \
          ${mesh_elmnt} model_configure module-setup.sh \
          nems.configure rpointer.atm rpointer.cpl ufs_common_debug.lua 
do 
  /bin/cp -f $WOLD/$fl .
done

export atm_mesh=cfsr_mesh.nc
cd $WD/DATM_INPUT
/bin/cp $WOLD/DATM_INPUT/$atm_mesh .

cd $WD/INPUT
/bin/cp $WOLD/INPUT/*.nc .
/bin/cp $WOLD/MOM_{input,layout,override} .
cd $WD

/bin/cp $SCR/arange_*.sh .
/bin/cp $SCR/check_*.sh .
for fscr in clean.sh continue_run.sh list_cycles.sh prepare_run.sh \
            rename_restart.sh run_next_cycle.sh sub_mom6cice.sh \
            wipe.sh
do
  /bin/cp $SCR/$fscr .
done

/bin/ln -sf arange_mom_restart_v2.sh arange_mom_restart.sh
for FLL in arange_cice_output.sh arange_mom_output.sh 
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
cd ${WD}
mkdir -pv config
for fll in data_table datm_in datm.streams diag_table ice_in input.nml \
           model_configure nems.configure
do
  /bin/mv $fll config/.
  /bin/ln -sf config/${fll} .
done



echo "All done"

exit 0 

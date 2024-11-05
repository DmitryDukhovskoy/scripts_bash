#!/bin/sh -x
#
# Prepare empty run directory for NEP MOM6-SIS2
# for new experiment that is run manually (not via xml)
# Usually for test runs
set -u

export DOLD=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_seasfcst_test
export DNEW=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_isponge_test
export SCR=/home/Dmitry.Dukhovskoy/scripts/MOM6_NEP
# Specify path, names of the executables used in this run
export DEXE=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/src/mom6/builds/build/gaea-ncrc5.intel23/ocean_ice/repro/
export UFSEXE=MOM6SIS2  # executable

mkdir -pv ${DNEW}
cd $DNEW
pwd

NOT FINISHED
copy dir with soft links preserved:
cp -R --preserve=links DIR1 DIR2

D=$DOLD
cd $DNEW
for fl in data_table diag_table field_table input.nml
  do 
    cp $D/$fl .
done

cp $D/*.sh .
cp -R --preserve=links $D/INPUT .
mkdir -pv RESTART


mkdir -pv DATM_INPUT
mkdir -pv history
mkdir -pv MOM6_OUTPUT
mkdir -pv INPUT
mkdir -pv RESTART
mkdir -pv log
mkdir -pv modulefiles
mkdir -pv config

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
cd ${WD}
for fll in data_table datm_in datm.streams diag_table ice_in input.nml \
           model_configure nems.configure
do
  /bin/mv $fll config/.
  /bin/ln -sf config/${fll} .
done



echo "All done"

exit 0 

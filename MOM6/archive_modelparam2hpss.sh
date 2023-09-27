#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J MOM6param
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=1:00:00
#
#
# prepare tar and move model param input files to HPSS
# copy log files
# usage: sbatch archive_modelparam2hpss.sh 
#
# NOAA/NWS/EMC Dmitry Dukhovskoy  2023
#

export expt=001
export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6_${expt}
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6/expt_${expt}
export SRC=/home/Dmitry.Dukhovskoy/scripts/MOM6

export chck_file=param_logs_sent2hpss

cd $DRUN

LTAR=model_params_008mom6cice6_${expt}.tar
echo "Tarring model param files ${LTAR}"
tar -cvf ${LTAR} data_table datm_in datm.streams diag_table fd_nems.yaml ice_in \
   input.nml list_cycles.txt model_configure nems.configure run_cycles.txt
wait

LLOG=logs_008mom6cice6_${expt}.tar
echo "Tarring model param files ${LLOG}"
tar -cvf ${LLOG} log/*
wait

pwd 
ls -l *.tar
echo "Moving $LTAR to HPSS:$HOUT"
hsi put $DRUN/${LTAR} : $HOUT/${LTAR}
wait

echo "Moving $LLOG to HPSS:$HOUT"
hsi put $DRUN/${LLOG} : $HOUT/${LLOG}
wait

touch $chck_file

exit 0


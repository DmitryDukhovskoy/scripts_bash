#!/bin/bash
#
# Run TS extraction script for MOM6
set -x 
set -u

DPY=/home/Dmitry.Dukhovskoy/python/anls_mom6
DRUN=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data_anls/RTOFS_production/extr_runs
DSCR=/home/Dmitry.Dukhovskoy/scripts/MOM6
DMOD=/home/Dmitry.Dukhovskoy/python/MyPython
scrpt=extrUVxsect_mom.py
YR=2021
dday=5    # data processing time stepping 
mS=1
dS=1
f_cont=False

mkdir -pv $DRUN
cd $DRUN
/bin/rm -f extrUV*mom*.py
/bin/rm -f extrUV*.log slurm*.out
/bin/rm -f pyjob_Unrm*sh

/bin/cp $DSCR/../rtofs/sub_pyjob.sh .

/bin/ln -sf $DPY/mod_mom6_valid.py
/bin/ln -sf $DPY/../validation_rtofs/mod_valid_utils.py
/bin/ln -sf $DPY/../rtofs/mod_utils.py
/bin/ln -sf $DMOD/hycom_utils/mod_read_hycom.py

/bin/cp $DPY/$scrpt .

icc=0
#for sname in BeringS DenmarkS IclShtl ShtlScot LaManch NAtl39 DavisS2 \
#            Fram79s2 BarentsS FlorCabl
for sname in DrakePsg
do
  for fld2d in Unrm
  do
    icc=$(( icc + 1 ))
    jnmb=$(echo ${icc} | awk '{printf("%03d",$1)}')
    aa=$(echo $scrpt | cut -d'.' -f1)
    scrpt_run=${aa}${jnmb}.py
    echo "extracting $sname $fld2d  ---> $scrpt_run"
    sed -e "s|^sctnm[ ]*= .*|sctnm = '${sname}'|"\
        -e "s|^YR1[ ]*= .*|YR1 = ${YR}|"\
        -e "s|^dS[ ]*= .*|dS = ${dS}|"\
        -e "s|^mS[ ]*= .*|mS = ${mS}|"\
        -e "s|^dday[ ]*= .*|dday = ${dday}|"\
        -e "s|^f_plt[ ]*= .*|f_plt = False|"\
        -e "s|^f_save[ ]*= .*|f_save = True|"\
        -e "s|^f_cont[ ]*= .*|f_cont = ${f_cont}|"\
        -e "s|^fld2d[ ]*= .*|fld2d = '${fld2d}'|" $scrpt > $scrpt_run

# Submitting run sbatch script
# sbatch -q batch -t 8:00:00 --nodes=1 -A marine-cpu batch.job
    subpy=pyjob_${fld2d}${jnmb}.sh
    sed -e "s|^pexe=.*|pexe=${scrpt_run}|" \
        -e "s|export WD=.*|export WD=${DRUN}|" sub_pyjob.sh > $subpy

# Capture the job id:
  job1id=$(sbatch -q batch -t 3:00:00 --nodes=1 -A fv3-cpu ${subpy} | cut -d " " -f4)
  echo "Submitted job $job1id"
###    sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh

  done
done 



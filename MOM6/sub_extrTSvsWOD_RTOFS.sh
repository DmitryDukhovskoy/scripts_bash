#!/bin/bash
#
# Run TS extraction script for RTOFS
# USing WOD uid
set -x 
set -u

DPY=/home/Dmitry.Dukhovskoy/python/anls_mom6
DRUN=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data_anls/RTOFS_production/
DSCR=/home/Dmitry.Dukhovskoy/scripts/MOM6
DMOD=/home/Dmitry.Dukhovskoy/python/MyPython
scrpt=extract_TSprofWOD_rtofs.py
YR=2023

mkdir -pv $DRUN
cd $DRUN
/bin/rm -f extract_TSprofWOD*.py
/bin/rm -f extract_TSprofWOD*.log 
#/bin/rm -f slurm*.out

/bin/cp $DSCR/../rtofs/sub_pyjob.sh .

/bin/ln -sf $DPY/mod_mom6_valid.py
/bin/ln -sf $DPY/../MyPython/mom6_utils/mod_mom6.py
/bin/ln -sf $DPY/../validation_rtofs/mod_valid_utils.py
/bin/ln -sf $DPY/../rtofs/mod_utils.py
/bin/ln -sf $DMOD/hycom_utils/mod_read_hycom.py

/bin/cp $DPY/$scrpt .

icc=0
for regn in AmundsAO NansenAO MakarovAO CanadaAO
do
  icc=$(( icc + 1 ))
  jnmb=$(echo ${icc} | awk '{printf("%03d",$1)}')
  aa=$(echo $scrpt | cut -d'.' -f1)
  scrpt_run=${aa}${jnmb}.py
  echo "extracting TS ${regn}   ---> $scrpt_run"
  sed -e "s|^regn[ ]*= .*|regn = '${regn}'|"\
      -e "s|^f_pltobs[ ]*= .*|f_pltobs = False|"\
      -e "s|^f_save[ ]*= .*|f_save = True|" $scrpt > $scrpt_run

# Submitting run sbatch script
# sbatch -q batch -t 8:00:00 --nodes=1 -A marine-cpu batch.job
  subpy=pyjob_${regn}${jnmb}.sh
  sed -e "s|^pexe=.*|pexe=${scrpt_run}|" \
      -e "s|export WD=.*|export WD=${DRUN}|" sub_pyjob.sh > $subpy

# Capture the job id:
  job1id=$(sbatch -q batch -t 6:00:00 --nodes=1 -A fv3-cpu ${subpy} | cut -d " " -f4)
  echo "Submitted job $job1id"
###    sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh

done 



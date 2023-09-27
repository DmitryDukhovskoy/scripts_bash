#!/bin/sh -x
#
# After fetching data from HPSS (get_qcdata_rtofs.sh)
# Submit parallel serial jobs to compute
# T/S profile statistics
# From RTOFS
#
# edit rdate - forecast date (Argo date will be automatically 
#              computed in python code
# nfls     - # of files to process on each node
#            40 files is ~20 min 
# Check directories
# run ./run_ts_stat.sh
#
set -u

export WD=/home/Dmitry.Dukhovskoy/python/TSrun
export SRC=/home/Dmitry.Dukhovskoy/python/rtofs
export BSH=/home/Dmitry.Dukhovskoy/scripts/rtofs
export pexe=tsprof_error_derive.py
export rdate=20230308
export nfls=40        # # of files 
export D0="/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data"
export Dargo="${D0}/rtofs.${rdate}/ocnqc_logs/profile_qc"

mkdir -pv $WD
cd $WD
/bin/cp $SRC/$pexe .
/bin/cp $BSH/sub_pyjob.sh .

# Copy necessary python modules:
/bin/cp $SRC/mod*.py .

# Clean old files
/bin/rm -f derive_run??.py

sed -i "s|^nprc[ ]*=.*|nprc  = ${nfls}|" ${pexe}

# split total records
ijb=0
nrec=$(grep "Temper" ${Dargo}/prof_argo_rpt.*.txt | wc -l)
for (( ii = 0; ii < nrec; ii = ii+nfls))
do
  ii1=$ii
  ii2=$((ii+nfls-1))
  if (( ii2 > nrec )); then
    ii2=$nrec
  fi
#
# Change start file #
  printf "Files to process = ${ii1} - ${ii2}"
  sed -i "s|^kk1[ ]*=.*|kk1   = ${ii1}|" $pexe
  sed -i "s|^rdate0[ ]*=.*|rdate0     = '${rdate}'|" $pexe

# Submitting run sbatch script
#sbatch -q batch -t 8:00:00 --nodes=1 -A marine-cpu batch.job
  ijb=$(( ijb + 1))
  if (( ijb > 50 )); then
    printf "Too many jobs, change nfls to reduce the jobs"
    exit 1
  fi

  jnmb=`echo ${ijb} | awk '{printf("%03d",$1)}'`
  fle="derive_run${jnmb}.py"
  cp ${pexe} ${fle}

  sed -e "s|^pexe=.*|pexe=${fle}|" \
      -e "s|export WD=.*|export WD=${WD}|" sub_pyjob.sh > pyjob${jnmb}.sh

  flog=testrun${jnmb}.log
  sbatch -q batch -t 3:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh &> $flog
   
done


exit 0

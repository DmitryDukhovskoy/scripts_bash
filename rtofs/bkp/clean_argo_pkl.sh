#!/bin/sh -x
# Clean argo TS temporarly pkl files created in run_ts_stat.sh 
# run on multiple nodes python code tsprof_error_anls.py
# 
# and all files being combined in python /rtofs run combine_stat.py
# to combine all separate files into 1 array
#
#
obs="profile_qc"  # obs type

if [[ $#<1 ]]; then
  printf " ERR: Usage get_qctar.sh YYYYMMDD [e.g., 20230123]"
  exit 1
fi

RD=$1
export D='/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data'
export DUMP="${D}/rtofs.$RD"
cd ${DUMP}/ocnqc_logs/${obs}/
pwd
ls -l

/bin/rm -f prof_argo_rpt.*.txt
/bin/rm -f TSprof_stat_????-????.pkl

exit 0




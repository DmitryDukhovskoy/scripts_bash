#!/bin/bash -x 
#
# Light cleaning
# Clean run directory only 
# Usage: 
# ./qclean_run.sh expt_name (e.g., paraD)
# if expt_name not provided, experiment in expt_name.txt will be used
#
set -u

if [[ $#<1 ]]; then
  printf " experiment name not provided will use from expt_name.txt"
  export expt=`cat expt_name.txt`
  echo $expt 
else
  expt=$1
fi

#export expt=paraD
export sfx="n-24"
export DHPSS=/NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.${expt}
export WD="/scratch1/NCEPDEV/stmp2/${USER}/rtofs_${expt}/run_diagn"
export lst=last_saved_${sfx}.txt
export hplst=hpss_output.txt
export hpdates=hpss_dates.txt
export DSCR=/home/Dmitry.Dukhovskoy/scripts/rtofs

cd $WD
pwd
ls -rlt

/bin/rm *.out
/bin/rm *.log
/bin/rm pyjob*.sh
/bin/rm plot_*0??.py
/bin/rm find_*0??.py
/bin/rm gulf*_*0??.py
/bin/rm -r __pycache__

exit 0


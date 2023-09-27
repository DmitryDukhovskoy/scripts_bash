#!/bin/bash --login
#
# Clean old diagnostics files and figures
# Use last_saved * txt 
# Usage: 
# ./clean_olddiagn.sh expt_name (e.g., paraD)
# if expt_name not provided, experiment in expt_name.txt will be used
#
set -x
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

du -h --max-depth=1

/bin/mv *.log logs/.

/bin/rm -f *.out
/bin/rm -f *.log
/bin/rm -f pyjob*.sh
/bin/rm -f plot_*0??.py
/bin/rm -f find_*0??.py
/bin/rm -f gulf*_*0??.py
/bin/rm -r __pycache__

for rdate in $(cat $lst)
do
  echo "Cleaning $rdate"
  /bin/rm rtofs.${rdate}/*.[ab]
  /bin/rm rtofs.${rdate}/fig/*.png

done

du -h --max-depth=1

exit 0


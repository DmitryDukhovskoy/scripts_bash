#!/bin/sh -vx
#
# Get QC log files with observations 
# and RTOFS files for T/S profile comparison
set -u

export WD=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/python/rtofs
export rdate=20230130    # f/cast date want to look at
export DRUN=NCEPDEV    # NCEPDEV or NCEPPROD
export expt=paraB      # RTOFS experiment
export ftype=incup    # output type: incup, bkgrd, f06, f12, f18, ... f96
export PSRC=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/python/rtofs
export SRC=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/scripts/rtofs
export D0=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data
export Dargo="${D0}/rtofs.${rdate}/ocnqc_logs/profile_qc"


cd $WD
pwd
ls -rlt *.sh

/bin/cp $SRC/get_qclog.sh .
/bin/cp $SRC/get_rtofs_archv.sh .
sed -i "s|export DRUN=.*|export DRUN=${DRUN}|" get_qclog.sh
sed -i "s|export expt=.*|export expt=${expt}|" get_qclog.sh
sed -i "s|export DRUN=.*|export DRUN=${DRUN}|" get_rtofs_archv.sh
sed -i "s|export expt=.*|export expt=${expt}|" get_rtofs_archv.sh
#exit 5
./get_qclog.sh $rdate
wait

# bkgrd - "-1 day" from current f/cast date after 24hr hindcast n00
#         may not be needed because QC log file has background profiles
#         if need to download - have to add calendar script to subtract 1 day
# incup - incr updated fields after 6hr, current date n-24
# forecasts - f12, ...
if [[ "$ftype" == "bkgrd" ]]; then
  printf "Need to add calendar awk to calculate -1 day for background"
  printf "Use QC log file for background profiles"
  exit 1
fi

if [[ "$ftype" == "incup" ]]; then
  sfx='n-24'
else
  sfx=$ftype
fi

./get_rtofs_archv.sh ${rdate} ${sfx}
wait

exit 0


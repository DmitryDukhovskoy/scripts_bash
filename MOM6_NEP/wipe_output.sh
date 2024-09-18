#!/bin/sh 
# 
# Clean run directory
# all log, err and output files
# keep 1 logfile>*>out
set -u

fll=logfile.000000.out
/bin/rm -f dmm.out
if [ -s $fll ]; then
  /bin/mv logfile.000000.out dmm.out
fi

/bin/rm -f logfile.*.out
if [ -s dmm.out ]; then
  /bin/mv dmm.out $fll
fi

/bin/rm err
/bin/rm job_timestamp.txt
/bin/rm time_stamp.out

/bin/rm -f *.ocean_????_???_??.nc
/bin/rm -f *.ice_daily.nc
/bin/rm -f ocean.stats*
/bin/rm -f seaice.stats
/bin/rm -f *_seastest.o*

exit 0


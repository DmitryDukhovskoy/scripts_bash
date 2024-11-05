#!/bin/sh 
# 
# Clean run directory
# keep 1 logfile>*>out
set -v
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
echo "Removing output fields"
/bin/rm -f ????????.oceanm*nc ????????.icem*nc

echo "Removing log files"
/bin/rm -f SIS_sponge.o*

# Removing error dump files from PEs:
/bin/rm -rf isponge_FMS2_MOM6_SIS2.x.80s*.btr

exit 0


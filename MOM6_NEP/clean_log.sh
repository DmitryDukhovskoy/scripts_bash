#!/bin/sh 
# 
# Clean run directory
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

exit 0


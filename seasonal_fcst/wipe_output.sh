#!/bin/sh 
# 
# Clean run directory
# all log, err and output files
# and clean RESTART
# Keeps main log file with job_id:
# SIS_sponge.o135187944
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

/bin/rm -f *.oceanm_???_??.nc
/bin/rm -f *.icem_????_??.nc
/bin/rm -f ocean.stats*
/bin/rm -f seaice.stats
#/bin/rm -f *_seastest.o*
/bin/rm -f RESTART/coupler.res
/bin/rm -f RESTART/ice_model.res.nc
/bin/rm -f RESTART/MOM.res.nc

exit 0


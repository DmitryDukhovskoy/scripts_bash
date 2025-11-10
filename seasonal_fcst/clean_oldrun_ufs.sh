#!/bin/sh 
# 
# Clean run directory
# keep 1 logfile>*>out
#set -v
set -u

#fll=logfile.000000.out
#/bin/rm -f dmm_logfile.out
#if [ -s $fll ]; then
#  /bin/mv logfile.000000.out dmm_logfile.out
#fi

/bin/rm -f logfile.*.out
rm -rf warnfile.*.out
#if [ -s dmm.out ]; then
#  /bin/mv dmm.out $fll
#fi

# Delete executable:
#echo "Deleting executable"
#/bin/rm -f fms_FMS2_MOM6_SIS2_compile_irlx.x

echo "Removing PET*LogFile"
rm -rf PET*ESMF_LogFile

echo "Removing MOM6_OUTPUT"
rm -rf MOM6_OUTPUT/*
rm -rf ocn_*.nc
rm -rf ocean_*.nc


rm -rf atm.log ice_diag.d out err
/bin/rm -rf job_timestamp.txt
#/bin/rm time_stamp.out

# Remove output log file:
rm -rf datm_mx025.o*

# update ice restart pointer:
echo "Updating ice.restart_file"
rm -rf ice.restart_file
echo -n  "./INPUT/cice_model.res.nc" > ice.restart_file
more ice.restart_file
#
#ln -sf ice.restart_file0 ice.restart_file

echo "Removing output fields"
/bin/rm -f ????????.oceanm*nc ????????.icem*nc

rm -rf core*
rm -rf log.*
rm -rf err*
rm -rf *.log
rm -rf ESMF_Profile.summary

rm -rf CICE_OUTPUT/*.nc
rm -rf history/*.nc

rm -rf RESTART/*

exit 0


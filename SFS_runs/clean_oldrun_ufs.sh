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
rm -rf oceanm_*.nc


rm -rf atm.log ice_diag.d out err
/bin/rm -rf job_timestamp.txt
#/bin/rm time_stamp.out

rm -rf FV3ATM_OUTPUT/*

# Remove output log file:
rm -rf sfs_mx025_c192.o*
rm -rf sfsC192mx025.o*

# update ice restart pointer:
echo "Updating ice.restart_file"
rm -rf ice.restart_file
echo -n  "./INPUT/cice_model.res.nc" > ice.restart_file
more ice.restart_file
ncdump -h ./INPUT/cice_model.res.nc | head -10
ncdump -h ./INPUT/cice_model.res.nc | tail -15
#
#ln -sf ice.restart_file0 ice.restart_file
echo "MOM.res.nc:"
ncdump -h INPUT/MOM.res.nc | tail -15

echo "Removing output fields"
/bin/rm -f ????????.oceanm*nc ????????.icem*nc

rm -rf core*
rm -rf log.*
rm -rf err*
rm -rf *.log
rm -rf logs.j*   # log dir
rm -rf ESMF_Profile.summary
rm -rf GFSPRS.GrbF*
rm -rf GFSFLX.GrbF*
rm -rf sfcf*.nc
rm -rf atmf*.nc

rm -rf CICE_OUTPUT/*.nc
rm -rf history/*.nc

rm -rf RESTART/*

# Check timing, note CICE6 timing depends on "continue" and "initial" setting
# and time in the restart file (reads when continue / restart is used) 
# or ice_in (reads ice_in in initial run)
echo "ice_in:"
grep "restart " ice_in
grep "_init" ice_in
grep "tr_pond_" ice_in
grep "ktherm" ice_in
grep "conduct" ice_in
grep " dt " ice_in
grep " ndtd " ice_in
grep " ndte " ice_in

echo "Model configure time:"
grep "start_" model_configure
grep "nhours_fcst" model_configure

echo "ufs.configure"
grep "stop_n =" ufs.configure

echo "Checking MOM6 restart option in input.nml (r = use restart, n = cold start)"
grep "input_filename" input.nml

exit 0


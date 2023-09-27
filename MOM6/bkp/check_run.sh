#! /bin/bash
set echo
head -2 diag_table
cat rpointer.* 
grep input_filename input.nml
export mcnfg=model_configure
echo "model_configure:"
grep start_year $mcnfg
grep start_month $mcnfg
grep start_day $mcnfg
grep start_hour $mcnfg
grep nhours_fcst $mcnfg
echo "   "
echo "datm.streams:"
grep 'stream_data_files01' datm.streams
ls -l `grep stream_data_files01 datm.streams | awk '{print $2}'`
grep year datm.streams
echo "   "
echo "nems.configure:"
grep stop_n nems.configure
grep restart_n nems.configure
echo "   "
echo "ice_in:"
cat ice.restart_file
grep runtype ice_in
grep grid_ice ice_in
grep kitd ice_in
grep ktherm ice_in
grep conduct ice_in
grep kdyn ice_in
grep shortwave ice_in
echo "   "
echo " -----"
grep start_type nems.configure
echo "dtlimit in datm.streams:"
grep dtlimit01 datm.streams

printf "\n MOM_input :"
export mominp=MOM_input
cd INPUT
idm=`grep "NIGLOBAL =" ${mominp} | cut -d " " -f 3`
jdm=`grep "NJGLOBAL =" ${mominp} | cut -d " " -f 3`
echo "Grid dim: IDM = $idm   JDM = $jdm"



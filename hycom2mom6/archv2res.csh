#!/bin/csh -x
#
module load comp/intel/2021.3.0 mpi/impi/2021.3.0 netcdf4/4.8.1-parallel
set echo
set time=1
date
#
# --- Create a MOM6  Netcdf -restart- file from a HYCOM archive
# --- requires a template MOM6 serial-IO restart
#
setenv YDH  2010_001_12
setenv DAY  `echo $YDH 3 | sed -e "s/_/ /g" | /discover/nobackup/projects/gmao/cal_ocn/abozec1/HYCOM-tools/bin/hycom_date_wind | sed -e 's/..$//g'`
setenv YMDH `echo $DAY 3 | /discover/nobackup/projects/gmao/cal_ocn/abozec1/HYCOM-tools/bin/hycom_wind_ymdh | sed -e "s/_//g"`
echo   "YDH  = " $YDH
echo   "DAY  = " $DAY
echo   "YMDH = " $YMDH
#
setenv root_dir /discover/nobackup/sakella/MOM6-GFDL/MOM6-testing/Alan.Wallcraft/

setenv TOOLS ${root_dir}/GLBb0.08/HYCOM_rst2_MOM6/HYCOM-tools/
setenv Topo  ${root_dir}/GLBb0.08_MOM6/topo/

setenv ARC   /discover/nobackup/projects/gmao/cal_ocn/sakella/from_Alan/hycom/GLBb0.08/expt_53.X/data
setenv RES   /discover/nobackup/projects/gmao/cal_ocn/sakella/make-MOM6_RST_from_hycom_arch/template_RES
setenv OUT   ${ARC}/RESTART_${YMDH}/

setenv hycom_restart archB.2010_001_00.a
#
if (! -e $OUT) mkdir -p $OUT
cd $ARC
#
rm -f regional.*
touch regional.depth.a regional.depth.b
if (-z regional.depth.a) then
  /bin/rm regional.depth.a
  /bin/cp ${Topo}/depth_GLBb0.08_09m11ob2.a regional.depth.a
endif
if (-z regional.depth.b) then
  /bin/rm regional.depth.b
  /bin/cp ${Topo}/depth_GLBb0.08_09m11ob2.b regional.depth.b
endif
#
touch regional.grid.a regional.grid.b
if (-z regional.grid.a) then
  /bin/rm regional.grid.a
  /bin/cp ${Topo}/regional.grid.a regional.grid.a
endif
if (-z regional.grid.b) then
  /bin/rm regional.grid.b
  /bin/cp ${Topo}/regional.grid.b regional.grid.b
endif
#
setenv HDF5_DISABLE_VERSION_CHECK 2
#
# flnm_i  : input hycom file -- we only need following (i.e., T, S, h, u and v).
# flnm_o  : mom6 restart from hycom
# flnm_rt : mom6 T restart template
# flnm_rs : mom6 S restart template
# flnm_rh : mom6 h restart template
# flnm_ru : mom6 u restart template
# flnm_rv : mom6 v restart template
/bin/rm -f ${OUT}/MOM.res.nc
${TOOLS}/archive/src/archv2mom6res <<E-o-D
${ARC}/${hycom_restart}
${OUT}/MOM.res.nc
${RES}/MOM.res.nc
${RES}/MOM.res_3.nc
${RES}/MOM.res_4.nc
4500   'idm   ' = longitudinal array size
3298   'jdm   ' = latitudinal  array size
  41   'kdm   ' = number of layers
${DAY} 'dayout' = output model day
   1   'symetr' = True (1) if MOM6 has symmetric arrays
   1   'arctic' = True (1) if global domain and Arctic patch
E-o-D
date


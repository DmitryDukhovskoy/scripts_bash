#!/bin/sh

set -x

home1=/scratch2/NCEPDEV/marine/$USER
Hfix=$home1/hycom_fix
Htools=/home/Dmitry.Dukhovskoy/HYCOM-tools
EXP=930
DHINP=${home1}/GLBb0.08_expt93.0 # HYCOM input archv

ln -sf $Hfix/regional* .
ln -sf $Hfix/relax.ssh.? .

YR=2020
JDAY=001
HR=00
rday=2020010100

# HYCOM archv file:
FLH=${EXP}_archv.${YR}_${JDAY}_${HR}
touch ${FLH}.a ${FLH}.b
if [[ ! -s ${FLH}.a ]] || [[ ! -s ${FLH}.b ]]; then
  /bin/rm ${FLH}.[ab]
  ln -sf ${DHINP}/${FLH}.a .
  ln -sf ${DHINP}/${FLH}.b .
fi
ls -l ${FLH}*

#  MOM6 templates:
/bin/rm -f MOM.res*.nc
ln -sf mom6_templ/MOM.res.nc .
ln -sf mom6_templ/MOM.res_*.nc .

#c
#c --- 'flnm_i'  = name of HYCOM archive file
#c --- 'flnm_o'  = name of MOM6 restart single file (output)
#c --- 'flnm_rt' = name of MOM6 restart temp  input
#c --- 'flnm_ru' = name of MOM6 restart u-vel input
#c --- 'flnm_rv' = name of MOM6 restart v-vel input
#! --- 'idm   ' = longitudinal array size
#! --- 'jdm   ' = latitudinal  array size
#! --- 'kdm   ' = number of layers

rm -f MOM.res.$rday
$Htools/archive/src/archv2mom6res << E-o-D
${FLH}.a
MOM.res.$rday.nc
MOM.res.nc
MOM.res_3.nc
MOM.res_4.nc
4500   'idm   ' = longitudinal array size
3298   'jdm   ' = latitudinal  array size
41     'kdm   ' = number of layers
737956 'dayout' = output model day
0     'symetr' = True if MOM6 has symetric arrays
1     'arctic' = True if global domain and Arctic patch
E-o-D

echo "All done"

exit 0

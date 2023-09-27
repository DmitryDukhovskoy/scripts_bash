#!/bin/sh
set -x

#/NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.prod/rtofs.[YYYYMMDD]
#first day is 20220526

RD=$1
export D='/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data'
mkdir -pv ${D}/rtofs.$RD
cd ${D}/rtofs.$RD

#htar -xvf /NCEPPROD/5year/hpssprod/runhistory/rh${RD:0:4}/${RD:0:6}/$RD/com_rtofs_prod_rtofs.$RD.ab.tar ./'*'n-24.archv.'*' ./'*'n00.archv.'*'
htar -xvf /NCEPPROD/5year/hpssprod/runhistory/rh${RD:0:4}/${RD:0:6}/$RD/com_rtofs_prod_rtofs.$RD.ab.tar ./'*'n-24.archv.'*'

tar -xvzf *.tgz
wait 



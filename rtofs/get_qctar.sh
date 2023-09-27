#!/bin/sh -x
#
# Get QC tar files with Argo profiles, etc
set -u

#/NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.prod/rtofs.[YYYYMMDD]
#first day is 20220526

obs="profile"  # what obs to keep

if [[ $#<1 ]]; then
  printf " ERR: Usage get_qctar.sh YYYYMMDD [e.g., 20230123]"
  exit 1
fi
 
RD=$1
export D='/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data'
mkdir -pv ${D}/rtofs.$RD
cd ${D}/rtofs.$RD

#htar -xvf /NCEPPROD/5year/hpssprod/runhistory/rh${RD:0:4}/${RD:0:6}/$RD/com_rtofs_prod_rtofs.$RD.ab.tar ./'*'n-24.archv.'*' ./'*'n00.archv.'*'
htar -xvf /NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.paraB/rtofs.${RD}/ocnqc.tar

#tar -xvzf *.tgz
wait 

cd ocnqc
pwd
ls -l

for dir in */
do
  if [ ! $dir == $obs ];  then
    printf " removing $dir "
    /bin/rm -r $dir
  fi
done 


exit 0


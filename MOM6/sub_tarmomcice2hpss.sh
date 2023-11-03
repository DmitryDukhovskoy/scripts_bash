#!/bin/bash -x
#
# Wrapper to call several scripts for
# tarring mom6, cice6 output and
# sending them to HPSS
# Note: *.nc output will be deleted from the
# output directory
# Can run for tarring 1 month
# or several months within 1 year
#
export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6

YR=2020
MM1=1
MM2=1

for (( MM = MM1; MM <= MM2; MM = MM+1 ));
do
  echo "Processing MOM6/CICE6 for $YR/$MM"

  ./archive_mom2hpss.sh $YR $MM
  ./archive_cice2hpss.sh $YR $MM
done

exit 0

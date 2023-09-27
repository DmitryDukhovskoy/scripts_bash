#!/bin/bash -x
#
# Extract hycom profiles for a given point
#
set -u

if [[ $#<2 ]]; then
  printf " ERR: Usage ./hycom_prof.sh YYYYMMDD [e.g., 20230123] n-24 [archive type]"
  exit 1
fi

RD=$1
sfx=$2
#export RD=20230418
#export sfx=n00
export WD=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/prof
export HT=/scratch2/NCEPDEV/marine/Zulema.Garraffo/HYCOM-tools
export PRM=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/hycom_fix
#export DEXP=/scratch2/NCEPDEV/marine/Zulema.Garraffo/wcoss2.paraD1
export DEXP=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/paraD1

DOUT=${DEXP}/rtofs.${RD}

cd $WD
ln -sf $PRM/regional.grid.? .

# Specify either lon/lat or grid indices
lon1=-999
lat1=-999
i1=602
j1=1609

if (( lon1 > -360 )) && (( lat1 > -90 )); then
  i1=`${HT}/bin/hycom_lonlat2ij $lon1 $lat1 | awk '{print $1}'`
  j1=`${HT}/bin/hycom_lonlat2ij $lon1 $lat1 | awk '{print $2}'`
fi

echo "i1=$i1 j1=$j1"

flout=profile_${RD}${sfx}_${i1}_${j1}.txt
/bin/cp -f ${HT}/bin/hycom_profile .
./hycom_profile ${DOUT}/rtofs_glo.t00z.${sfx}.archv.a $i1 $j1 > ${flout}


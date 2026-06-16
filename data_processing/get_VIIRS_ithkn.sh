#!/bin/bash 
#
# VIIRS high res ice thickness data (750m)
# Careful with downloading data, better to use OpenDAP in python
#

URL=https://www.star.nesdis.noaa.gov/thredds/dodsC/IceThickVIIRSnppSectorFourDayNP06/
pthdata=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/VIIRS_ithkn_highres

usage() {
  echo "Usage: $0 --yr 2021 --mm  --dd 15"
  echo "  --yr   Year for downloading: 2011, ..., 2026 complete years"
  echo "  --mm   Month for downloading: 1, ..., 12"
  echo "  --dd   Day of the month"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --yr)
      YR=$2
      shift 2
      ;;
    --mm)
      MM=$2
      shift 2
      ;;
    --dd)
      DD=$2
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

cd $pthdata || { echo "Failed cd ${pthdata}"; exit 1; }

# Script is not finished:
# Need to convert date ---> julian day
# also for 4- day composite, need to find start- end days
# This is just an example:
MM0=$(printf "%02d" $MM)
flin=VXSACW_B2021251_B2021254_H4_NP06_edgemask_IceThickness.nc
wget --content-disposition "${URL}/${YR}/${flin}?"

exit 0

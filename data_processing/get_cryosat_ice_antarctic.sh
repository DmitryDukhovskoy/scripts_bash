#!/bin/bash 
# Cryosat data of antarctic monthly ice thickness, snow thickness
#  Available data from July 2020 - Aug 2021
#
# Note: Zenodo recently changed how it delivers files:
#
#The old “/records/.../files/...” paths now often redirect to temporary, tokenized download URLs (for access control and usage tracking).
#
#The browser automatically follows these redirects and includes authentication cookies, but wget does not — so you get a 404 Not Found.
#
#Option: Use the DOI or record URL with wget --content-disposition
#
#Zenodo supports direct file downloads via the DOI redirect, e.g.:

URL=https://zenodo.org/record/7327711/files
pthdata=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/CryoSat2_antarctic_ice_snow_thkn

usage() {
  echo "Usage: $0 --ys 2011 --ye 2020"
  echo "  --ys   Start year for downloading: 2011, ..., 2020 complete years"
  echo "  --ye   End year for downloading: 2011, ..., 2020"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YRS=$2
      shift 2
      ;;
    --ye)
      YRE=$2
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

for (( yr=YRS; yr <= YRE; yr++ )); do
  for (( MM=1; MM <= 12; MM++ )); do
    MM0=$(printf "%02d" $MM)
    flin=CS2WFA_25km_${yr}${MM0}.nc
    wget --content-disposition "${URL}/${flin}?download=1"
  done
done

exit 0

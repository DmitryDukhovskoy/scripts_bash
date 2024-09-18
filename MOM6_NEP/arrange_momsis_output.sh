#!/bin/bash -x
#
# Arrange MOM & SIS2 output after completing 1 cycle
# Rename files - get rid of the leading datestamp
#
# Move output files to directories grouped by months
# Prepare files for tarring and moving to HPSS storage
#
# Output files in work directory 
# both MOM6 and SIS2 are high frequency output (e.g., 5-day average)
# and saved in the format: YYYYMMDD.{oceanm,icem}_YYYY_DDD.nc 
# 
# e.g.: 19930401.oceanm_1993_108.nc, 19930401.icem_1993_108.nc
#
# Dmitry Dukhovskoy, NOAA/OAR/PSL
# 2024
#
set -u

export expt='NEP_seasfcst_test'
export DW=/gpfs/f5/cefi/scratch/$USER/work/$expt
export DWS=/ncrc/home1/$USER/scripts
export oprfx='oceanm'
export iprfx='icem'

function get_file_name {
  local FL=$1
  bsname=$(echo ${FL} | cut -d "." -f 2)
  YY=$(echo ${bsname} | cut -d "_" -f 2)
  jday=$(echo ${bsname} | cut -d "_" -f 3)

  MM=`echo "YRDAY2MDAY" | awk -f dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$2)}'`
  mday=`echo "YRDAY2MDAY" | awk -f dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$3)}'`
}

cd $DW
/bin/cp $DWS/awk_utils/dates.awk .

# File names are assumed: YYYYMMDD.ocean_YYYY_DDD_HR.nc
# where the date at the begining of the file name is the beginning of the simulation
# Check if there are output files:
pwd
noutp=`ls -1 *.${oprfx}_*.nc | wc -l`
if [[ $noutp == 0 ]]; then
  echo " No MOM6 output found in $DW "
  echo " Exiting ..."
  exit 0
fi

echo "Found $noutp MOM output files in ${DW}"

# Get output dates
for prfx in $oprfx $iprfx; do
  for FL in $(ls *.${prfx}_*.nc)
  do
    get_file_name ${FL}

    DOUT=${prfx}_${YY}${MM}
    if [ ! -d $DOUT ]; then
      /bin/mkdir -pv ${DW}/${DOUT}
    fi

    FLout=${bsname}.nc
    echo "Moving $FL ---> ${DOUT}/${FLout}"
    /bin/mv $FL $DOUT/${FLout}    
   
  done 
done


exit 0

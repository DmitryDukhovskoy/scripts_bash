#!/bin/bash -x
#
# Arrange MOM output after completing 1 cycle
# Move output files to directories grouped by months
# Prepare files for tarring and moving to HPSS storage
#
# Output files in work directory 
# Daily output files 
# 
# Dmitry Dukhovskoy, NOAA/NWS/EMC 
# July 2023
#
set -u

export DW=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6
export DWS=/home/Dmitry.Dukhovskoy/scripts
export prfx='ocnm'

cd $DW
/bin/cp $DWS/awk_utils/dates.awk .

# Check if there are output files:
pwd
noutp=`ls -1 ${prfx}_*.nc | wc -l`
if [[ $noutp == 0 ]]; then
  echo " No output found in $DW "
  exit 0
fi

echo "Found $noutp MOM output files in ${DW}"

# Get output dates
# File name is assumed *_YYYY_DDD_*
for FL in $(ls ${prfx}_*.nc)
do
  YY=$(echo ${FL} | cut -d "_" -f 2)
  jday=$(echo ${FL} | cut -d "_" -f 3)

  MM=`echo "YRDAY2MDAY" | awk -f dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$2)}'`
  mday=`echo "YRDAY2MDAY" | awk -f dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$3)}'`
 
  DOUT=tarmom_${YY}${MM}
  if [ ! -d $DOUT ]; then
    /bin/mkdir -pv ${DW}/${DOUT}
  fi
  echo "Moving $FL ---> ${DOUT}"
  /bin/mv $FL $DOUT/.    
 
done 


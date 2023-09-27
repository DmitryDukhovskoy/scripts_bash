#!/bin/bash -x
#
# Arange CICE output after completing 1 cycle
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

export expt=002
export DW=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6_${expt}
export DICE=$DW/history
export DWS=/home/Dmitry.Dukhovskoy/scripts
export prfx='iceh'

#cd $DW
#/bin/cp $DWS/awk_utils/dates.awk .

# Check if there are output files:
cd $DICE
pwd
noutp=`ls -1 ${prfx}.*.nc | wc -l`
if [[ $noutp == 0 ]]; then
  echo " No CICE output found in $DICE "
  echo " Exiting ..."
  exit 0
fi

echo "Found $noutp CICE output files in ${DICE}"

# Get output dates
# File name is assumed *YYYY-MM-MDAY*
for FL in $(ls ${prfx}.*.nc)
do
  dmm=$(echo ${FL} | cut -d "." -f 2)
  YY=$(echo ${dmm} | cut -d "-" -f 1)
  MM=$(echo ${dmm} | cut -d "-" -f 2)
  mday=$(echo ${dmm} | cut -d "-" -f 3)

  DOUT=tarcice_${YY}${MM}
  if [ ! -d $DOUT ]; then
    /bin/mkdir -pv ${DW}/${DOUT}
  fi
  echo "Moving $FL ---> ${DW}/${DOUT}"
  /bin/mv $FL ${DW}/$DOUT/.    
 
done 

exit 0

#!/bin/bash -x
#
# Arrange MOM & SIS2 output after completing 1 cycle
# Move output files to directories grouped by months
# Prepare files for tarring and moving to HPSS storage
#
# Output files in work directory 
# Daily output files 
# 
# Dmitry Dukhovskoy, NOAA/OAR/PSL
# 2024
#
set -u

export expt='NEP_BGCphys'
export DW=/gpfs/f5/cefi/scratch/$USER/work/$expt
export DWS=/ncrc/home1/$USER/scripts
export prfx='ocean'

cd $DW
/bin/cp $DWS/awk_utils/dates.awk .

# File names are assumed: YYYYMMDD.ocean_YYYY_DDD_HR.nc
# where the date at the begining of the file name is the beginning of the simulation
# Check if there are output files:
pwd
noutp=`ls -1 *.${prfx}_*.nc | wc -l`
if [[ $noutp == 0 ]]; then
  echo " No MOM6 output found in $DW "
  echo " Exiting ..."
  exit 0
fi

echo "Found $noutp MOM output files in ${DW}"

# Get output dates
for FL in $(ls *.${prfx}_*.nc)
do
  bsname=$(echo ${FL} | cut -d "." -f 2)
  YY=$(echo ${bsname} | cut -d "_" -f 2)
  jday=$(echo ${bsname} | cut -d "_" -f 3)

  MM=`echo "YRDAY2MDAY" | awk -f dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$2)}'`
  mday=`echo "YRDAY2MDAY" | awk -f dates.awk y01=$YY d01=$jday | awk '{printf("%02d",$3)}'`
 
  DOUT=tarmom_${YY}${MM}
  if [ ! -d $DOUT ]; then
    /bin/mkdir -pv ${DW}/${DOUT}
  fi

  FLout=${bsname}.nc
  echo "Moving $FL ---> ${DOUT}/${FLout}"
  /bin/mv $FL $DOUT/${FLout}    
 
done 

# Arrange SIS output
# daily and monthly means
cd $DW
nioutp=`ls -1 *.ice_*.nc | wc -l`
if [[ $nioutp > 0 ]]; then
  echo "Found $nioutp ice output files"
fi

DIOUT=ice_output
/bin/mkdir -pv ${DW}/${DIOUT}
for FL in $(ls *.ice_*.nc)
do
  bsname=$(echo ${FL} | cut -d "." -f 2)
  datestamp=$(echo ${FL} | cut -d "." -f 1)
  YY=${datestamp:0:4}
  FLICE=${bsname}_${datestamp}.nc
  echo "Moving $FL ---> $DIOUT/$FLICE"
  /bin/mv $FL $DIOUT/$FLICE
done 

exit 0

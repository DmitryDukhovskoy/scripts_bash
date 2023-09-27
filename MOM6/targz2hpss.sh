#!/bin/bash -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J MOM6tarXX
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=04:00:00
#
# the script is called by archive_*sh for tarring and 
# sending to hpss
#
# NOAA/NWS/EMC Dmitry Dukhovskoy  2023
#

export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6

#export Nft=6     # # of output files in 1 tar file
export fnm=ocnm
export chck_file=tar_sent2hpss
export flst=tar_list_xxx.txt
export FTAR=mom6_xxx

/bin/tar -czvf ${FTAR}.tar.gz -T $flst
wait
date


# Put tar files to HPSS
#To put the file local_file into the HPSS directory /BMC/testproj/myid/work
#hsi put /full_local/path/local_file : /BMC/testproj/myid/work/local_file
echo "Moving $FTAR to HPSS:$HOUT"
hsi put $DRUN/${FTAR}.tar.gz : $HOUT/${FTAR}.tar.gz
wait

# Check if the data have been moved:
ntar=`hsi -P ls -1 $HOUT | grep ${FTAR}.tar.gz | wc -l`
echo $ntar
if [[ $ntar == 0 ]]; then
  echo "!!! $FTAR not found on HPSS $HOUT !!!"
else
  echo "${FTAR}.tar.gz is on HPSS"
  touch $chck_file
#
# Remove *nc
#  echo "${FTAR}.tar.gz is on HPSS, removing local ${FTAR}.tar.gz"
#   /bin/rm -f $ftar
  echo "Removing tarred files from the list"
  for fl in $( cat $flst ); do 
    /bin/rm $fl
  done

fi

exit 0


#!/bin/bash -x
##SBATCH --nodes=1 --tasks-per-node=1
##SBATCH -J HYCOM_archv
##SBATCH -A marine-cpu
##SBATCH --partition=service 
##SBATCH -q debug
##SBATCH --time=06:00:00
#
# No need to run on compute nodes, the script will launch 
# jobs for tarring
#
# prepare tar and move ice output files to PPANLS/archive
# all output should be in ice_output directories
# prepared in arange_mom_output.sh
#
# Usage: ./archive_ice2ppanls.sh - move all ice output nc files
#
# NOAA/OAR/PSL Dmitry Dukhovskoy  2024
#
set -u

#module load gcp 

export YR=1993
export expt='NEP_BGCphys_GOFS'
export DRUN=/gpfs/f5/cefi/scratch/${USER}/work/${expt}
export SRC=/ncrc/home1/${USER}/scripts/MOM6_NEP
export IDIR=ice_output

if [[ $# == 1 ]]; then
  YR=$1
fi

#export HOUT=/work/${USER}/run_output/${expt}/${YR}
export HOUT=/archive/${USER}/${expt}/${YR}/ice
#export chck_file=tar_sent2ppanls

cd $DRUN/${IDIR}
pwd
noutp=`ls -1 ice_*_${YR}*.nc | wc -l`
if [[ $noutp == 0 ]]; then
  echo " No ice fields for ${YR} found in $DRUN/${IDIR}"
  echo " Exiting"
  exit 0
fi

FL=$(ls ice_static_${YR}*.nc)
bsname=$(echo ${FL} | cut -d "." -f 1)
datestamp=$(echo ${bsname} | cut -d "_" -f 3)
TARF=ice_output_${datestamp}
if [ -e $TARF.tar.gz ]; then
  echo "$TARF exists"
else
  echo "Tarring $YR  $noutp output files --> ${TARF}.tar.gz"
  tar czvf ${TARF}.tar.gz ice*${datestamp}.nc
  wait
fi

ls -rlth

#
# Edit gcp_tar2ppanls.sh --> gcp_tar2ppanlsXX.sh for correct year/month
# sbatch --dependency=afterok:$jobid gcp_tar2ppanlsXX.sh
# No need to submit a job for gcp - it is automatically run
# via rdtn es transfer job
chck_file=${TARF}_sent
if [ -e ${chck_file} ]; then
  echo "$TARF has been sent, quitting ..."
  exit 0
fi
echo "Sending  $TARF.tar.gz --> PPANLS:$HOUT "
gcp -cd ${TARF}.tar.gz gfdl:${HOUT}/
wait

status=$?
if [[ $status == 0 ]]; then
  `echo $TARF.tar.gz > $chck_file`

  echo "Cleaning output fields"
  /bin/rm ice*${datestamp}.nc
fi

#HGCP=gcp_icetar2ppanls.sh
#HGCPX=gcp_icetar2ppanls_${YR}.sh
#/bin/cp $SRC/${HGCP} .
#sed -e "s|^export YR=.*|export YR=$YR|"\
#    -e "s|^export DRUN=.*|export DRUN=$DRUN|"\
#    -e "s|^export IDIR=.*|export IDIR=$IDIR|"\
#    -e "s|^export tarf=.*|export tarf=$TARF.tar.gz|"\
#    -e "s|^export expt=.*|export expt=$expt|"\
#    -e "s|^export HOUT=.*|export HOUT=$HOUT|" $HGCP > $HGCPX 
#
#chmod 750 $HGCPX
#
#sbatch $HGCPX
#wait

ls -rlt
echo "All done"

exit 0


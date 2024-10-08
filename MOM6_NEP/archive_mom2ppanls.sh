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
# prepare tar and move MOM6 output files to HPSS
# all output should be in tarmom_YYYYMM directories
# prepare in arange_mom_output.sh
#
# To keep tar files managable - tar only Nft = 6 files in 1 tar file
#
# Usage: ./archive_mom2ppanls.sh - move all tarmom_*
#     OR ./archive_mom2ppanls.sh YYYY move tarmom_YYYY*
#     OR Year and Month: ./archive_mom2ppanls.sh YYYY MM  ---> move tarmom_YYYYMM
#
# NOAA/OAR/PSL Dmitry Dukhovskoy  2024
#
set -u

#module load gcp 

export YR=1993    # year to process
export expt='NEP_seasfcst_test'
export DRUN=/gpfs/f5/cefi/scratch/${USER}/work/${expt}
export SRC=/ncrc/home1/${USER}/scripts/MOM6_NEP
export prfx=oceanm

if [[ $# == 1 ]]; then
  YR=$1
fi

MMT=0
if [[ $# == 2 ]]; then
  MMT=$2
fi

export Nft=11     # # of output files in 1 tar file
#export HOUT=/work/${USER}/run_output/${expt}/${YR}
export HOUT=/archive/${USER}/NEP_LZRESCALE/${YR}
#export chck_file=tar_sent2ppanls

cd $DRUN
for fdir in $(ls -d ${prfx}_${YR}??)
do
#  cd $DRUN 
  dmm=`echo $fdir | cut -d "_" -f2`
  YRD=`echo ${dmm:0:4}`
  MMD=`echo ${dmm:4:6}`
# Clearly specify decimals for correct interpretation of
# the numbers with leading 0's, 08 = 8, otherwise
# it will be interpreted as octal number
  if (( 10#$YR > 0 )) && (( 10#$YRD != 10#$YR )); then
    continue
  fi

  if (( 10#$MMT > 0 )) && (( 10#$MMD != 10#$MMT )); then
# Stop if specified month has been passed
    if (( 10#$MMD > 10#$MMT )); then 
      echo "Done"
      exit 0
    fi

    echo "Skipping month $MMD"
    continue
  fi

  cd ${DRUN}/${fdir}
# Assumed that no *.nc exist if tar has been created and sent to remote storage
#  if [[ -f $chck_file ]]; then
#    echo "No tar is needed, Output from $fdir has been sent to remote archive"
#    cd $DRUN
#    continue
#  fi
  nfls=`ls -l ${prfx}_${YRD}*nc 2>/dev/null | wc -l`
  if (( $nfls == 0 )); then
    echo "$fdir no MOM output found"
    continue
  fi

  echo "Tarring $YRD $MMD:  $nfls output files "

# ====================
# Create list of tar files groupping them by Nft in 1 tar
  ntar=1
  nfiles=0

  /bin/rm -f tarlist_*.txt
  echo "Creating list of files for tarring"
  for floutp in $(ls ${prfx}_${YRD}*nc)
  do
    flist=tarlist_${prfx}_${YRD}${MMD}_${ntar}.txt
    echo $flist
    touch $flist
    echo $floutp >> $flist
    nfiles=$(( nfiles+1 ))

    if [[ $nfiles == $Nft ]]; then
      nfiles=0 
      ntar=$(( ntar+1 ))
    fi
  done      
  ls -l tarlist*txt

  echo "Tarring ..."

  ntar=1
  for flst in $(ls tarlist*txt)
  do
    echo $flst
    FTAR=${prfx}_${YRD}${MMD}_${ntar}
    HEXE=targz_${prfx}_${YRD}${MMD}_${ntar}.sh
# Do not overwrite existing tars:
    if [ -s ${FTAR}.tar.gz ]; then
      echo "${FTAR}.tar.gz exists in ${DRUN}/${fdir}"
      echo "Skipping creating ${FTAR}.tar.gz"
      continue
    fi
#    /bin/cp $SRC/targz2ppanls.sh .
    TARGZ=targz_momsis.sh
    /bin/cp $SRC/$TARGZ .

    sed -e "s|^export flst=.*|export flst=$flst|"\
        -e "s|^export FTAR=.*|export FTAR=$FTAR|"\
        -e "s|^export HOUT=.*|export HOUT=$HOUT|"\
        -e "s|^export DRUN=.*|export DRUN=${DRUN}/${fdir}|"\
        -e "s|^export ntar=.*|export ntar=${ntar}|" $TARGZ > $HEXE

    chmod 750 ${HEXE}
    echo "sbatch $HEXE"
    jobid=$(sbatch $HEXE | cut -d " " -f4)
    echo "Submitted job $jobid"
    ntar=$(( ntar+1 ))
#
# Transfer to pp/anls: job-dependency
# Edit gcp_tar2ppanls.sh --> gcp_tar2ppanlsXX.sh for correct year/month
# sbatch --dependency=afterok:$jobid gcp_tar2ppanlsXX.sh
    HGCP=gcp_tar2ppanls.sh
    HGCPX=gcp_tar2ppanls_${ntar}.sh
    /bin/cp $SRC/${HGCP} .
    sed -e "s|^export YR=.*|export YR=$YRD|"\
        -e "s|^export MMT=.*|export MMT=$MMD|"\
        -e "s|^export expt=.*|export expt=$expt|"\
        -e "s|^export prfx=.*|export prfx=$prfx|"\
        -e "s|^export HOUT=.*|export HOUT=$HOUT|" $HGCP > $HGCPX 

    chmod 750 $HGCPX
    sbatch --dependency=afterok:$jobid $HGCPX
  done
# ====================
  cd $DRUN
done


exit 0


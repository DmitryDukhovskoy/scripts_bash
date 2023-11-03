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
# prepare tar and move CICE6 output files to HPSS
# all output should be in tarmom_YYYYMM directories
# prepare in arange_mom_output.sh
#
# To keep tar files managable - tar only Nft = 6 files in 1 tar file
#
# Usage: ./archive_cice2hpss.sh ---> move all tarcice_*
#     OR ./archive_cice2hpss.sh YYYY ---> move tarcice_YYYY*
#     OR specify Year and Month: ./archive_cice2hpss.sh YYYY MM  ---> move tarcice_YYYYMM
#
# NOAA/NWS/EMC Dmitry Dukhovskoy  2023
#

export expt=003
export DRUN=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/MOM6_run/008mom6cice6_${expt}
export HOUT=/NCEPDEV/emc-ocean/5year/Dmitry.Dukhovskoy/MOM6/expt_${expt}
export SRC=/home/Dmitry.Dukhovskoy/scripts/MOM6

YR=2020
if [[ $# == 1 ]]; then
  YR=$1
fi

MMT=0
if [[ $# == 2 ]]; then
  MMT=$2
fi

if [[ $# > 2 ]]; then
  echo "More than 2 input parameters, max = 2"
  echo "Usage:   ./archive_cice2hpss.sh YYYY MM"
  echo "      OR ./archive_cice2hpss.sh YYYY"
  echo "      OR ./archive_cice2hpss.sh ---> move all tarcice_*"
  exit 5
fi

export Nft=6     # # of output files in 1 tar file
export fnm=iceh
export chck_file=tar_sent2hpss

cd $DRUN
for fdir in $(ls -d tarcice_${YR}*)
do
  cd $DRUN 
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
    echo "Skipping month $MMD"
    continue
  fi

  cd $fdir
# First check if tar has been created and sent to HPSS
  if [[ -f $chck_file ]]; then
    echo "No tar is needed, Output from $fdir has been sent to HPSS"
    cd $DRUN
    continue
  fi
  nfls=`ls -l ${fnm}.${YRD}*nc 2>/dev/null | wc -l`
  if (( $nfls == 0 )); then
    pwd
    ls
    echo "$fdir no CICE output found"
    continue
  fi

  echo "Tarring $nfls output files "

# ====================
# Create list of tar files groupping them by Nft in 1 tar
  ntar=1
  nfiles=0

  /bin/rm -f tarlist_*.txt
  echo "Creating list of files for tarring"
  for floutp in $(ls ${fnm}.${YRD}*nc)
  do
    flist=tarlist_cice_${YRD}${MMD}_${ntar}.txt
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
    FTAR=cice_${YRD}${MMD}_${ntar}
    HEXE=targz_cice_${YRD}${MMD}_${ntar}.sh
    /bin/cp $SRC/targz2hpss.sh .

    sed -e "s|^export flst=.*|export flst=$flst|"\
        -e "s|^export FTAR=.*|export FTAR=$FTAR|"\
        -e "s|^export HOUT=.*|export HOUT=$HOUT|"\
        -e "s|^export DRUN=.*|export DRUN=${DRUN}/${fdir}|"\
        -e "s|^#SBATCH -J .*|#SBATCH -J CICE6tar${ntar}|" targz2hpss.sh > $HEXE

    chmod 750 $HEXE

    echo "sbatch $HEXE"
    sbatch $HEXE
    ntar=$(( ntar+1 ))

  done
# ====================
  cd $DRUN
done


exit 0


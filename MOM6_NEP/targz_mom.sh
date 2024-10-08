#!/bin/bash -x
#SBATCH -e tar%j.err
#SBATCH -o tar%j.out
#SBATCH --account=cefi
##SBATCH --clusters=c5
#SBATCH --clusters=es
#SBATCH --partition=ldtn_c5
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --export=NONE
#
# tar/gzip MOM and SIS output files
#
# the script is called by archive_mom2ppanls*sh for tarring and 
# sending to PP/ANLS
#
#
#module load gcp 

#export DRUN=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/XXXX/tarmom_XXX
#export HOUT=/XXX/XXX/XXX
export DRUN=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_BGCphys/tarmom_199301
export HOUT=/work/Dmitry.Dukhovskoy/run_output/NEP_BGCphys/1993


export fnm=ocean
export ntar=XX
export chck_file=tar_sent2ppanls_${ntar}
export flst=tar_list_xxx.txt
export FTAR=mom6sis_xxx

cd $DRUN
/bin/rm -f $chck_file
pwd
echo "Tarring $flst"
if ( -s ${FTAR}.tar.gz ); then
  echo "${FTAR}.tar.gz exists, tar not created "
  exit 1
else
  /bin/tar -czvf ${FTAR}.tar.gz -T $flst
  wait
fi
date


# Put tar files to PP/ANLS
# GCP provides an option for automatically creating new directories (-cd).
# The final segment of the path is interpreted as a directory 
# if a trailing slash is included. 
# Otherwise, it will be interpreted as a file.
#echo "Moving $FTAR to PP/ANLS:$HOUT"
#gcp -cd ${FTAR}.tar.gz gfdl:${HOUT}/  
#wait

# Check tar:
nflst=`cat ${flst} | wc -l` 
nfltar=`tar tzvf ${FTAR}.tar.gz | wc -l`

echo "${nflst} files in ${flst} = ${nfltar} in ${FTAR}.tar.gz?"
if (( $nflst == $nfltar )); then
  echo "ok"
else
  echo "Failed, ERROR"
  exit 1
fi

#touch $chck_file
#
# Remove *nc
#   /bin/rm -f $ftar
echo "Removing tarred files from the list"
for fl in $( cat $flst ); do 
  echo $fl
  /bin/rm $fl
done

exit 0


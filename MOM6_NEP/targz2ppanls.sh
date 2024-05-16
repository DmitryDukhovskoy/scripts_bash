#!/bin/bash -x
#SBATCH -e tar%j.err
#SBATCH -o tar%j.out
#SBATCH --account=cefi
#SBATCH --clusters=es
#SBATCH --partition=ldtn
##SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --export=NONE
#
#
# the script is called by archive_mom2ppanls*sh for tarring and 
# sending to PP/ANLS
#
#
module load gcp 

#export DRUN=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/XXXX/tarmom_XXX
#export HOUT=/XXX/XXX/XXX
export DRUN=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/work/NEP_BGCphys/tarmom_199301
export HOUT=/work/Dmitry.Dukhovskoy/run_output/NEP_BGCphys/1993


export fnm=ocean
export ntar=XX
export chck_file=tar_sent2ppanls_${ntar}
export flst=tar_list_xxx.txt
export FTAR=mom6_xxx

cd $DRUN
/bin/rm -f $chck_file
pwd
echo "Tarring $flst"
/bin/tar -czvf ${FTAR}.tar.gz -T $flst
wait
date


# Put tar files to PP/ANLS
# GCP provides an option for automatically creating new directories (-cd).
# The final segment of the path is interpreted as a directory 
# if a trailing slash is included. 
# Otherwise, it will be interpreted as a file.
echo "Moving $FTAR to PP/ANLS:$HOUT"
gcp -cd ${FTAR}.tar.gz gfdl:${HOUT}/  
wait


touch $chck_file
#
# Remove *nc
#   /bin/rm -f $ftar
echo "Removing tarred files from the list"
#for fl in $( cat $flst ); do 
#  echo $fl
#  /bin/rm $fl
#done

exit 0


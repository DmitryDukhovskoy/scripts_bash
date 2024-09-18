#!/bin/bash -x
#SBATCH -e tar%j.err
#SBATCH -o tar%j.out
#SBATCH --account=cefi
#SBATCH --clusters=es
#SBATCH --partition=rdtn_c5
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
##SBATCH --export=NONE
#
# transfer SIS2 ice output to PP/ANLS
# https://gaeadocs.rdhpcs.noaa.gov/wiki/index.php?title=Data_transfers
#
set -u

module load gcp 

export expt='NEP_BGCphys'
export DRUN=/gpfs/f5/cefi/scratch/${USER}/work/${expt}
export SRC=/ncrc/home1/${USER}/scripts/MOM6_NEP
export fnm=ocean
export YR=1993
#export HOUT=/work/${USER}/run_output/${expt}/${YR}
export HOUT=/archive/${USER}/${expt}/${YR}
export IDIR=ice_output
export tarf=XXXX.tar.gz
export chck_file=${tarf}_sent

/bin/rm $tarf

cd $DRUN/$IDIR
echo "Sending  $tarf --> PPANLS:$HOUT "
gcp -cd ${tarf} gfdl:${HOUT}/
wait

`echo $tarf > $chck_file`

exit 0


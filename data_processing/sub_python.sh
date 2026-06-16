#!/bin/sh 
#SBATCH -e err
#SBATCH -o out
#SBATCH --job-name=interp_gfs16
#SBATCH --account=sfs-cpu
#SBATCH --qos=normal
##SBATCH --qos=debug
#SBATCH --clusters=c6
#SBATCH --partition=batch
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --output=%x.o%j
#SBATCH --time=8:00:00
##SBATCH --time=0:30:00
#
# Submit python job 
# on interactive node
#
WD=/ncrc/home1/Dmitry.Dukhovskoy/python/prepare_cice6
pexe=interp_GFSv16_iceflds_mesh025.py
fname=hsnow

cd $WD
pwd
ls -la
eval "$($PYPATH/bin/conda shell.bash hook)"
conda activate $cndn

which ipython

echo "Submitting ipython < ${pexe}"
ls -l ${pexe}
#ipython < run ${pexe}
ipython ${pexe} --ftmp 1 --init 20240715 --fhrS 6 --fhrE 384 --hrav 24 --field ${fname} >> ${pexe}.log

exit 0




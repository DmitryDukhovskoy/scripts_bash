#!/bin/sh -x
#SBATCH --nodes=1 --tasks-per-node=1
#SBATCH -J CFSRtransfer
#SBATCH -A marine-cpu
#SBATCH --partition=service 
##SBATCH -q debug
#SBATCH --time=06:00:00
# 
# Bring files for all 12 months for year until YR2
# in YR2 - only until MM2, e..g to have extra month 
# to complete the run
# to extract 1 month: make YR1=YR2, MS1=x, ME2=x+1
set -u

export DR=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/CFSR
export HDR=/NCEPDEV/marineda/5year/DATM_INPUT/CFSR
# Specify start/end year/month assuming continuous
# range of months from YRS/MS1 to YRE/ME2
export YRS=2021
export MS1=9
#export ME1=9
export YRE=2021
#export MS2=9
export ME2=9

for (( YR = YRS; YR <= YRE; YR = YR+1 ))
do 
  if [[ $YR == $YRS ]]; then
    MM1=$MS1
    if [[ ${YRS} == ${YRE} ]]; then
      ME=$ME2
    else
      ME=12
    fi
  else
    MM1=1
    ME=$ME2
  fi

#
#  if [[ $YR == $YR2 ]]; then
#    MM1=$MS2
#    ME=$ME2
#  else
#    MM1=$MS1
#    ME=$ME1
#  fi
#
  for (( MM = MM1; MM <= ME; MM = MM+1 ))
  do
    ldir=`echo ${YR} ${MM} | awk '{printf("%04d%02d", $1, $2)}'`
    cd ${DR}
    mkdir -pv ${ldir}
    cd ${DR}/${ldir}
    pwd
    printf "Fetching CFSR ${YR} ${MM} ---> ${DR}/${ldir}"
    htar -xvf ${HDR}/${ldir}/cfsr.${ldir}.tar 
#    exit 5
    wait
  done
done




#! /bin/sh 
# Check if all files have been transferred and untarred from HPSS2
# before merging them
#
set -u

export DR=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/CFSR
export SRC=/home/Dmitry.Dukhovskoy/scripts/MOM6
export YR1=2021
export MM1=1
export YR2=2022
export MM2=1
export nrcday=4    # N recrods per day

cd $DR
cp $SRC/dates.awk .

nsaved_tot=0
ndays_tot=0
for (( YR = YR1; YR <= YR2; YR = YR+1 ))
do
  if [[ $YR == $YR2 ]]; then
    MM1=1
    ME=$MM2
  else
    ME=12
  fi

  for (( MM = MM1; MM <= ME; MM = MM+1 ))
  do
    ldir=`echo ${YR} ${MM} | awk '{printf("%04d%02d", $1, $2)}'`
    nfls=$( ls -1 ${ldir}/*.${YR}??????.nc | wc -l )
# 
# Calc. how many days/records are expected for this month/year
    day1=$( echo "YRMO START DAY" | awk -f dates.awk y01=$YR MM=$MM dd=1 | awk '{printf("%d", $1)}' )
    day2=$( echo "YRMO START DAY" | awk -f dates.awk y01=$YR MM=$MM dd=1 | awk '{printf("%d", $2)}' ) 
    ndays=$(( day2-day1+1 ))
    nrecs=$(( ndays*nrcday ))

    if [[ 10#$nrecs != 10#$nfls ]]; then
      echo "Mismatched saved / expected recrods ${YR}/${MM}: $nfls / $nrecs"
    else
      echo "${YR}${MM} ok"
    fi

    nsaved_tot=$(( nsaved_tot+nfls ))
    ndays_tot=$(( ndays_tot+ndays ))
  done
done

echo "============================="
echo "Total files transferred: $nsaved_tot"
echo "Total days: $ndays_tot
echo "Expected recrods: $(( ndays_tot*nrcday ))

exit 0




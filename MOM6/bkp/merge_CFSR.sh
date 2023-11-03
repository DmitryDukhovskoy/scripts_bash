#! /bin/sh -x
# Merge individual CFSR files into 1
# for time period YR1/MM1 - YR2/MM2
# use interactive queue to run the script
# salloc --x11=first --ntasks 2 --qos=batch --time=08:00:00 --account=marine-cpu
set -u

export DR=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/CFSR
export YR1=2021
export MM1=1
export YR2=2022
export MM2=1

mkdir -pv ${DR}/dump

irec=1
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
    cd ${DR}/${ldir}
    pwd

    for flnc in $( ls cfsr.${ldir}????.nc )
    do
      dstmp=`echo $flnc | cut -d "." -f 2`
      flnc_new=cfsr.${dstmp}_${irec}.nc
      echo "Adding time ${flnc} ---> ${flnc_new}"
      ncks --mk_rec_dmn time ${flnc} ${flnc_new} 

      irec=$(( irec+1 ))
    done
    mv ${DR}/${ldir}/cfsr.*_*.nc ${DR}/dump
  done
done

echo " YR=$YR MM=$MM irec=$irec"
echo " Start merging "
cd ${DR}/dump

pwd
nfls=`ls -1 | wc -l`
echo "Total # of files $nfls"
echo "Records $irec"

CM1=`echo ${MM1} | awk '{printf("%02d", $1)}'`
CM2=`echo ${MM2} | awk '{printf("%02d", $1)}'`
flout=cfsr_${YR1}${CM1}_${YR2}${CM2}.nc

/bin/rm -f ${DR}/${flout}
ncrcat cfsr.*_*.nc out.nc
ncatted -O -a units,time,m,c,"seconds since 1970-01-01 00:00:00.0" out.nc out2.nc
mv -f out2.nc $flout
wait

/bin/rm out*.nc
/bin/mv $flout $DR/.
cd $DR

# Clean tmp dir:
/bin/rm -f dump/*
# Also need to clesn original fields in YYYYMM directories
# /bin/rm ${YR1}??/*.nc
# /bin/rm ${YR2}??/*.nc

echo "All done"
exit 0




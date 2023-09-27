#!/bin/bash --login
#
# Transfer figures prepared in ../rtofs_diagnostics/para_diagnostics.sh
# to rzdm web directory
# and submit a script to arrange figures and *.php for 
# displaying plot on a website
#
set -x
set -u

module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
module purge
module load intel/2022.1.2 impi/2022.1.2 contrib ncl/6.6.2 netcdf/4.6.1 hdf5 cdo/1.9.10 nccmp/1.9.0.1 nco/4.9.3 cairo/1.14.2 hpss/hpss
module list


#/bin/ln -sf ../rtofs_diagnostics/expt_name.txt
touch expt_name.txt
/bin/rm -f expt_name.txt
/bin/cp -f ../rtofs_diagnostics/expt_name.txt .
#if [ ! -s expt_name.txt ]; then
#  echo "Need to provide experiment name in expt_name.txt"
#  exit 1
#fi

# During automated run, expt and sfx will be updated automatically
# by the data-transfer script in ../rtofs_diagnostics/ 
export expt=paraD5b
export sfx=n-24
#export expt=paraD3
#export sfx="n-24"
export WD=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/rtofs_paraD5b/run_diagn
export DTR=/home/Dmitry.Dukhovskoy/scripts/transfer2rzdm
export lst=last_saved_n-24.txt
export fmssd=hpss_missed.txt

ID=ddukhovskoy@emcrzdm.ncep.noaa.gov
RZDMDUMP=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/dump
RZDMDIR=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/develop
RZDMBIN=/home/people/emc/ddukhovskoy/bin

# Process missed dates
# Check if figures have been created
cd $WD
for rdate in $(cat $fmssd)
do
  cd $WD
  export DOUT=$WD/rtofs.${rdate}
  export DFIG=$DOUT/fig

# Check dir exist and not empty
  if [ -d $DFIG ]
  then
    nfgs=`ls -1 ${DFIG}/*.png | wc -l`
  else
    nfgs=0
  fi

#Transfer figures to rzdm:
  if [[ $nfgs == 0 ]]
  then
    echo "Figures in $DFIG are not ready"
    continue
  fi

  echo "starting rsync with rzdm, $nfgs figures"
  cd $DTR
  flw1=set_web_dir.sh
  flw2=set_web_dirR.sh
  sed -e "s|^export expt=.*|export expt=${expt}|"\
      -e "s|^export sfx=.*|export sfx=${sfx}|"\
      -e "s|^export rdate=.*|export rdate=${rdate}|" ${flw1} > ${flw2}

  chmod 750 $flw2

  /usr/bin/rsync -av -e ssh --progress ${DFIG}/*.png ${ID}:${RZDMDUMP}/.
#    /usr/bin/rsync -av -e ssh --progress ${DTR}/index_*.php ${ID}:${RZDMDIR}/.
  /usr/bin/rsync -av -e ssh --progress ${DTR}/index_showimages.php ${ID}:${RZDMDIR}/.
  /usr/bin/rsync -av -e ssh --progress ${DTR}/img.php ${ID}:${RZDMDIR}/.
  /usr/bin/rsync -av -e ssh --progress ${DTR}/${flw2} ${ID}:${RZDMBIN}/.
  wait

#/usr/bin/ssh ${POLAR} /home/others/people/emc/zulema.garraffo/bin/make_web_link.sh
  /usr/bin/ssh ${ID} /home/people/emc/ddukhovskoy/bin/${flw2}
  wait


#
# Update last saved fig list:
  echo "Updating saved list"
  cd $WD
  nlsv=`grep ${rdate} $lst | wc -l`
  if [[ $nlsv == 0 ]]; then
    echo $rdate >> $lst
  fi
# Update list of missed dates:
  /bin/cp $fmssd dmm.txt
  grep -wv ${rdate} dmm.txt > $fmssd 
  /bin/rm dmm.txt
# 
# Create cleanup script

done  # rdate loop


echo " ==== TRANSFER 2 RZDM and WWW setup DONE ===="

exit 0


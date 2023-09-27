#!/bin/bash -x 
#
# Transfer figures prepared in ../rtofs_diagnostics/para_diagnostics.sh
# to rzdm web directory
# and submit a script to arrange figures and *.php for 
# displaying plot on a website
#
set -u

export expt=paraD
export sfx="n-24"
export WD="/scratch1/NCEPDEV/stmp2/${USER}/rtofs_${expt}/run_diagn"
export DTR=/home/Dmitry.Dukhovskoy/scripts/transfer2rzdm
export lst=last_saved_${sfx}.txt
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
  else
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

  fi

#
# Update last saved fig list:
#  echo "Updating saved list"
#  cd $WDR
#  echo $rdate >> $lst
# 
# Create cleanup script

done  # rdate loop

echo " ==== TRANSFER 2 RZDM and WWW setup DONE ===="

exit 0


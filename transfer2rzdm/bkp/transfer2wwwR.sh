#!/bin/bash -x 
##!/bin/bash -l
##!/bin/ksh --login
set -u

export expt=paraD
export sfx=n-24
export WD=/scratch1/NCEPDEV/stmp2/Dmitry.Dukhovskoy/rtofs_paraD/run_diagn
export DTR=/home/Dmitry.Dukhovskoy/scripts/transfer2rzdm
export lst=last_saved_n-24.txt
export fmssd=hpss_missed.txt

ID=ddukhovskoy@emcrzdm.ncep.noaa.gov
RZDMDUMP=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/dump
RZDMDIR=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/develop
RZDMBIN=/home/people/emc/ddukhovskoy/bin

# Process missed dates
# Check if figures have been created
for rdate in $(cat $fmssd)
do
  export DOUT=$WD/rtofs.${rdate}
  export DFIG=$DOUT/fig

# Check dir exist and not empty
  if [ -d $DFIG ]
  then
    nfgs=`ls -1 *.png | wc -l`
  else
    nfgs=0
  fi

#Transfer figures to rzdm:
  TRANSFER=${DFIG}

  if [[ $nfgs == 0 ]]
  then
    echo "Figures in $DFIG are not ready"
  else
    echo "starting rsync with rzdm, $nfgs figures"
#/usr/bin/rsync -a --rsh /usr/bin/ssh --rsync-path /usr/bin/rsync --timeout=1200  --exclude='*.ps' $TRANSFER/  ${ID}:${RZDMDIR}
    cd $DTR
    flw1=set_web_dir.sh
    flw2=set_web_dirR.sh
    sed -e "s|^export expt=.*|export expt=${expt}|"\
        -e "s|^export sfx=.*|export sfx=${sfx}|"\
        -e "s|^export rdate=.*|export rdate=${rdate}|" ${flw1} > ${flw2}

    chmod 750 $flw2

    /usr/bin/rsync -av -e ssh --progress ${DFIG}/*.png ${ID}:${RZDMDUMP}/.
    /usr/bin/rsync -av -e ssh --progress ${DTR}/${flw2} ${ID}:${RZDMBIN}/.
    wait

#/usr/bin/ssh ${POLAR} /home/others/people/emc/zulema.garraffo/bin/make_web_link.sh
    /usr/bin/ssh ${ID} /home/people/emc/ddukhovskoy/bin/${flw2}

  fi

done  # rdate loop

echo " ==== TRANSFER 2 RZDM and WWW setup DONE ===="

exit 0


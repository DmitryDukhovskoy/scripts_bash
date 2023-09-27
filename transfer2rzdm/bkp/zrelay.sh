#!/bin/bash -x 
##!/bin/bash -l
##!/bin/ksh --login
set -u

export expt=paraD
export sfx="n-24"
export WD="/scratch1/NCEPDEV/stmp2/${USER}/rtofs_${expt}/run_diagn"

export rdate=20230303
export DOUT=$WD/rtofs.${rdate}
export DFIG=$DOUT/fig

TRANSFER=${DFIG}
ID=ddukhovskoy@emcrzdm.ncep.noaa.gov
#TRANSFER=/scratch2/NCEPDEV/marine/Zulema.Garraffo/rtofs_plots
#POLAR=zulema.garraffo@emcrzdm.ncep.noaa.gov
#POLARDIR=/home/www/polar/develop/global/zulema
RZDMDIR=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/develop

echo "starting rsync with polar"
#/usr/bin/rsync -a --rsh /usr/bin/ssh --rsync-path /usr/bin/rsync --timeout=1200  --exclude='*.ps' $TRANSFER/  ${ID}:${RZDMDIR}

#cd ${DFIG}
#pwd
/usr/bin/rsync -av -e ssh --progress ${DFIG}/*.png ${ID}:${RZDMDIR}/.
/usr/bin/rsync -av -e ssh --progress ${WD}/new_web_dir.sh ${ID}:${RZDMDIR}/.

#/usr/bin/ssh ${POLAR} /home/others/people/emc/zulema.garraffo/bin/make_web_link.sh
#/usr/bin/ssh ${ID} /home/people/emc/ddukhovskoy/bin/new_web_dir.sh

#!/bin/bash -l
#
# this is the global image transfer task
#

RD=20221111
LOCAL_DIR="/scratch2/NCEPDEV/marine/Zulema.Garraffo/rtofs_plots/$RD"
REMOTE_DIR="/home/www/emc/htdocs/users/zulema/develop"
REMOTE_ID="zulema.garrafo@emcrzdm.ncep.noaa.gov"


  scp -q -o "BatchMode yes" $LOCAL_DIR/*.gif ${REMOTE_ID}:$REMOTE_DIR/$RD/. 
#  ssh ${REMOTE_ID} /home/people/emc/zulema.garraffo/bin/make_web_link.sh

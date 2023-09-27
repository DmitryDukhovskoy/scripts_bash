#!/bin/bash -x
# Script for setting www directories
# for displaying figures
#to see the directories on the website when going from one to another I have to do the following:
# 1) in the subdirectory copy index.php (the one that refers to dirlist.php)
# 2) make all dir chmod 755 - executable, readable to all and editable by the owner
# 3) in the directories that you want to be visible on the website, 
#  there should be executable index.php (whatever you like) or this can be 
#  easily modified in the dirlist.php where the code is checking that
# 4) edit allow.cfg by adding directory names you want to be shown on the 
#  website (dirlist.php is looking for directory names in 
#  this list and if the name is not there - does not show it on the website)
# 5) copy the allow.cfg to your subdirectory 
#
# Dir structure: region --> 2D maps (SSH, fronts, ...)
#                       --> Lrs (WE, SN sections)
#                       --> S sections
#                       --> T sections
#
# Note file naming convention is important, assumed structre
# with fields separated by "_" 
#
#
set -u

export expt=paraD
export sfx=n-24
export rdate=20230303

DDIR=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/develop
DDUMP=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/dump
FFX=png

chmod a+rx $DDIR

cd $DDIR
mkdir -pv $rdate
chmod 755 $rdate

cd $DDIR/$rdate
/bin/rm -f index.php allow.cfg
/bin/cp $DDIR/index.php .
/bin/cp ${DDIR}/allow.cfg .

for frgn in NAtl SAtl NPac SPac IndO Glb
do
# Make sure the directory is listed in allow.cfg
    cd $DDIR/$rdate
    nvar=`grep $frgn allow.cfg | wc -l`
    if [[ $nvar == 0 ]]; then
      echo $frgn >> allow.cfg
    fi

  mkdir -pv $DDIR/$rdate/$frgn
  cd $DDIR/$rdate/$frgn
  /bin/rm -f index.php allow.cfg
  /bin/cp $DDIR/index.php .
  /bin/cp ${DDIR}/allow.cfg .

  for flds in Lrs SctS SctT maps
  do
#
# Make sure the directory is listed in allow.cfg
    cd $DDIR/$rdate/$frgn
    nvar=`grep $flds allow.cfg | wc -l`
    if [[ $nvar == 0 ]]; then
      echo $flds >> allow.cfg
    fi

    mkdir -pv $DDIR/$rdate/$frgn/$flds
    chmod 755 $DDIR/$rdate/$frgn/$flds
    cd $DDIR/$rdate/$frgn/$flds
   
    /bin/rm -f *${expt}*${rdate}*.png *.php

    nfigs=`ls -1 $DDUMP/${flds}*${expt}_${rdate}_${sfx}*${frgn}*png | wc -l`
    if [[ $nfigs == 0 ]]; then
      echo "No figures found $DDUMP/${flds}*${expt}_${rdate}_${sfx}*${frgn}*png"
      continue
    fi
    /bin/mv $DDUMP/${flds}*${expt}_${rdate}_${sfx}*${frgn}*png .

# Numerate EW SN sections for ordering:
# Find region name before .png and change to a number
    if [[ "$flds" == "Lrs" || "$flds" == "SctS" || "$flds" == "SctT" ]]; then
      iEW=1
      iSN=2
      for fignm in ${flds}EW*.png
      do
#        fldE=`echo $fignm | rev | cut -d "_" -f1 | rev | cut -d "." -f1`
        fldE=${flds}EW
        fnmb=`echo $iEW | awk '{printf("%03d"), $1}'`        
        flnew=`echo $fignm | sed "s|${fldE}|fig${fnmb}|"`
        /bin/mv ${fignm} ${flnew}
        iEW=$(( iEW+2 ))
      done         
      for fignm in ${flds}SN*.png
      do
#        fldE=`echo $fignm | rev | cut -d "_" -f1 | rev | cut -d "." -f1`
        fldE=${flds}SN
        fnmb=`echo $iSN | awk '{printf("%03d"), $1}'`        
        flnew=`echo $fignm | sed "s|${fldE}|fig${fnmb}|"`
        /bin/mv ${fignm} ${flnew}
        iSN=$(( iSN+2 ))
      done         
    fi

    /bin/cp ${DDIR}/img.php .
    /bin/cp ${DDIR}/index_showimages.php .
    ln -sf index_showimages.php index.php
#      ls -l
  done   # plotted fields
done     # plotted regions
chmod 755 -R $DDIR/$rdate


exit 0


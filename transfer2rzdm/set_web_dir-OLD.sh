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

for frgn in NAtl SAtl NPac SPac IndO 
do
  mkdir -pv $DDIR/$rdate/$frgn

  cd $DDIR/$rdate/$frgn
  /bin/rm -f index.php allow.cfg
  /bin/cp $DDIR/index.php .
  /bin/cp ${DDIR}/allow.cfg .

  for flds in Lrs
  do
    mkdir $flds
    chmod 755 $flds
    cd $flds
   
    /bin/rm -f ${flds}*${rdate}*${sfx}*${frgn}*png 
    /bin/mv $DDUMP/${flds}*${expt}_${rdate}_${sfx}*${frgn}*png .

# Get rid off datestamp etc to match index php
    for fignm in *.png
    do
      fld1=`echo $fignm | cut -d "_" -f1`
      fld2=`echo $fignm | cut -d "_" -f5`
      fld3=`echo $fignm | cut -d "_" -f6`
      flnew="${fld1}_${fld2}_${fld3}"
#      /bin/mv $fignm $flnew
      ln -sf $fignm $flnew
      chmod 755 $flnew
      /bin/cp ${DDIR}/index_${frgn}_${flds}.php .
      ln -sf index_${frgn}_${flds}.php index.php
#      ls -l
    done
  done   # plotted fields
done     # plotted regions
chmod 755 -R $DDIR/$rdate


exit 0


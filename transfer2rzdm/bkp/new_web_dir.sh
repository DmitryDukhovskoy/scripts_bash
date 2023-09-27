#!/bin/bash

rdate=20230303
#DDIR=/home/www/polar/develop/global/zulema
DDIR=/home/www/emc/htdocs/users/Dmitry.Dukhovskoy/develop
set -x

chmod a+rx $DDIR

cd $DDIR
mkdir -pb $rdate
chmod 755 $rdate

for subdir in 20??????; do
  if [ $subdir < 20220715 ]; then
  if [[ ! -a $subdir/index.php ]]; then
    ln -s ../index_template.php $subdir/index.php
  fi
  else
  if [[ ! -a $subdir/index.php ]]; then
    ln -s ../index_template_secs.php $subdir/index.php
  fi
  fi

done
for subdir in 20??????_*; do
  if [[ ! -a $subdir/index.php ]]; then
    ln -s ../index_template_secs.php $subdir/index.php
  fi
done
for subdir in 20??????.*; do
  if [[ ! -a $subdir/index.php ]]; then
    ln -s ../index_template_secs.php $subdir/index.php
  fi
done

for subdir in 20????????_impacts*; do
  if [[ ! -a $subdir/index.php ]]; then
    ln -s ../index_template_impacts.php $subdir/index.php
  fi
done

#for subdir in run4_movies Dan3_movies 20210707*; do
#  if [[ ! -a $subdir/index.php ]]; then
#    ln -s ../index_template_movies_secs.php $subdir/index.php
#  fi
#done

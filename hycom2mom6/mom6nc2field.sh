#!/bin/sh

home1=/scratch2/NCEPDEV/marine/Zulema.Garraffo

cp $home1/HYCOM-tools/mom6/src/mom6nc2field3d .
#u_2021060900 is 4500 x 3298, right values
./mom6nc2field3d <<E-o-D
u
MOM.res.2021060900.nc
u_2021060900.a
  1     'inirec' = initial time record to read in
  1     'maxrec' = final   time record to read in, 0 for to the end
  1     'increc' =         time record increment
E-o-D


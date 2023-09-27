#!/bin/sh

home1=/scratch2/NCEPDEV/marine/$USER
SRC=/home/$USER
Hfix=$home1/hycom_fix
Htools=$home1/HYCOM-tools
DINP=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/GLBb0.08_expt93.0

ln -s $Hfix/regional* .
ln -s $Hfix/relax.ssh.? .

rday=2020010109
E=930       # GOFS experiment
YIN=2020
JDAYIN=001
HRIN=00

farchv=${E}_archv.${YIN}_${JDAYIN}_${HRIN}
/bin/rm ${farchv}.[a,b]
ln -sf ${DINP}/${farchv}.a .
ln -sf ${DINP}/${farchv}.b .


#
# ---  input archive file
# ---  input restart template file
# --- output restart file
#
rm -f archv.$rday.?
$Htools/archive/src/restart2archv << E-o-D
restart_r${rday}_$E.b
archv.$rday.b
930     'iexpt '   = experiment number x10  (000=from archive file)
3       'yrflag'   = days in year flag (0=360J16,1=366J16,2=366J01,3=actual)
1       'sshflg'   = diagnostic SSH flag (0=SSH,1=SSH&stericSSH using relax.ssh.a)
1       'iceflg'   = ice model flag (0=none(default),1=energy loan model)
4500    'idm   '   = longitudinal array size
3298    'jdm   '   = latitudinal  array size
-1      'kapref'   = thermobaric reference state (-1 to 3, optional, default 0)
41      'kdm   '   = number of layers
1       'n     '   = extract restart time slot number (1 or 2)
  34.0    'thbase' = reference density (sigma units)
  17.00   'sigma ' = layer  1 isopycnal target density (sigma units)
  18.00   'sigma ' = layer  2 isopycnal target density (sigma units)
  19.00   'sigma ' = layer  3 isopycnal target density (sigma units)
  20.00   'sigma ' = layer  4 isopycnal target density (sigma units)
  21.00   'sigma ' = layer  5 isopycnal target density (sigma units)
  22.00   'sigma ' = layer  6 isopycnal target density (sigma units)
  23.00   'sigma ' = layer  7 isopycnal target density (sigma units)
  24.00   'sigma ' = layer  8 isopycnal target density (sigma units)
  25.00   'sigma ' = layer  9 isopycnal target density (sigma units)
  26.00   'sigma ' = layer 10 isopycnal target density (sigma units)
  27.00   'sigma ' = layer 11 isopycnal target density (sigma units)
  28.00   'sigma ' = layer 12 isopycnal target density (sigma units)
  29.00   'sigma ' = layer 13 isopycnal target density (sigma units)
  29.90   'sigma ' = layer 14 isopycnal target density (sigma units)
  30.65   'sigma ' = layer  A isopycnal target density (sigma units)
  31.35   'sigma ' = layer  B isopycnal target density (sigma units)
  31.95   'sigma ' = layer  C isopycnal target density (sigma units)
  32.55   'sigma ' = layer  D isopycnal target density (sigma units)
  33.15   'sigma ' = layer  E isopycnal target density (sigma units)
  33.75   'sigma ' = layer  F isopycnal target density (sigma units)
  34.30   'sigma ' = layer  G isopycnal target density (sigma units)
  34.80   'sigma ' = layer  H isopycnal target density (sigma units)
  35.20   'sigma ' = layer  I isopycnal target density (sigma units)
  35.50   'sigma ' = layer 15 isopycnal target density (sigma units)
  35.80   'sigma ' = layer 16 isopycnal target density (sigma units)
  36.04   'sigma ' = layer 17 isopycnal target density (sigma units)
  36.20   'sigma ' = layer 18 isopycnal target density (sigma units)
  36.38   'sigma ' = layer 19 isopycnal target density (sigma units)
  36.52   'sigma ' = layer 20 isopycnal target density (sigma units)
  36.62   'sigma ' = layer 21 isopycnal target density (sigma units)
  36.70   'sigma ' = layer 22 isopycnal target density (sigma units)
  36.77   'sigma ' = layer 23 isopycnal target density (sigma units)
  36.83   'sigma ' = layer 24 isopycnal target density (sigma units)
  36.89   'sigma ' = layer 25 isopycnal target density (sigma units)
  36.97   'sigma ' = layer 26 isopycnal target density (sigma units)
  37.02   'sigma ' = layer 27 isopycnal target density (sigma units)
  37.06   'sigma ' = layer 28 isopycnal target density (sigma units)
  37.10   'sigma ' = layer 29 isopycnal target density (sigma units)
  37.17   'sigma ' = layer 30 isopycnal target density (sigma units)
  37.30   'sigma ' = layer 31 isopycnal target density (sigma units)
  37.42   'sigma ' = layer 32 isopycnal target density (sigma units)
E-o-D

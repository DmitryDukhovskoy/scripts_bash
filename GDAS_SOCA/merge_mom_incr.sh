#! /bin/sh -x
#
# Merge 2 netcdf files with RTOFS NCODA increments for MOM6
# into 1 file required by GDAS

CRES=384
ORES=008
EXPT=C${CRES}O${ORES}
DRIN=/scratch1/NCEPDEV/stmp2/Zulema.Garraffo/FV3_RT/expt_11.9/rtofs.20220219/INPUT
ICSDIR=/scratch2/NCEPDEV/marine/Dmitry.Dukhovskoy/data/GDAS/ICSDIR/C${CRES}O${ORES}

ADATE=20210702
HR=00
DROUT=$ICSDIR/gdas.${ADATE}/${HR}/ocean
fincr1=MOM.inc.TSzh.nc
fincr2=MOM.inc.UV.nc
fincrout=gdas.t${HR}z.ocninc.nc

echo "Merging NCODA incr files: $DRIN/${fincr1}, ${fincr2} --->"
echo " --> $DROUT/$fincrout"

# For ncrcat need to add a record variable (unlimited dimension, "Time", e.g)
#/bin/cp $DRIN/${fincr1} $DROUT/.
#/bin/cp $DRIN/${fincr2} $DROUT/.

cd $DROUT
ls -l
echo "Adding Time dimension to TSzh increments $fincr1"
/bin/rm tmp*.nc
/bin/rm tmp*nc*.tmp
ncap2 -s 'defdim("Time",1,0);Time[Time]=1;Time@long_name="Time";Time@units="time level";Time@cartesian_axis="T"' ${fincr1} tmp1.nc
ncrename -d Level,Layer tmp1.nc

ncap2 -4 --thr_nbr=1 --cnk_csh=1000000000 --cnk_byt=4000000000 \
--cnk_min=8 --cnk_dmn=lonh,1000 --cnk_dmn=lath,1000 \
-s 'Temp[Time,Layer,lath,lonh]=pt_inc' tmp1.nc tmp1.nc

ncap2 -4 -O --thr_nbr=1 --cnk_csh=1000000000 --cnk_byt=4000000000 \
--cnk_min=8 --cnk_dmn=lonh,1000 --cnk_dmn=lath,1000 \
-s 'Salt[Time,Layer,lath,lonh]=s_inc' tmp1.nc tmp1.nc

ncap2 -4 -O --thr_nbr=1 --cnk_csh=1000000000 --cnk_byt=4000000000 \
--cnk_min=8 --cnk_dmn=lonh,1000 --cnk_dmn=lath,1000 \
-s 'h[Time,Layer,lath,lonh]=zh' tmp1.nc tmp1.nc

# Delete unneded vars:
echo "Cleaning ncfile TSzh"
ncks -O -x -v pt_inc,s_inc,zh tmp1.nc tmp1.nc

echo "Adding Time dimension to UV increments $fincr2"
ncap2 -s 'defdim("Time",1,0);Time[Time]=1;Time@long_name="Time";Time@units="time level";Time@cartesian_axis="T"' ${fincr2} tmp2.nc
ncrename -d Level,Layer tmp2.nc

ncap2 -4 -O --thr_nbr=1 --cnk_csh=1000000000 --cnk_byt=4000000000 \
--cnk_min=8 --cnk_dmn=lonq,1000 --cnk_dmn=lath,1000 \
-s 'u[Time,Layer,lath,lonq]=u_inc' tmp2.nc tmp2.nc

ncap2 -4 -O --thr_nbr=1 --cnk_csh=1000000000 --cnk_byt=4000000000 \
--cnk_min=8 --cnk_dmn=lonh,1000 --cnk_dmn=latq,1000 \
-s 'v[Time,Layer,latq,lonh]=v_inc' tmp2.nc tmp2.nc

# Delete unneded vars:
echo "Cleaning ncfile UVincr"
ncks -O -x -v u_inc,v_inc tmp2.nc tmp2.nc


#ncap2 -4 -D 4 --thr_nbr=1 --cnk_csh=1000000000 --cnk_plc=g3d \
# --cnk_dmn=lonh,1000 --cnk_dmn=lath,1000 \
# -s 'Temp[Time,Layer,lath,lonh]=pt_inc' tmp1.nc tmp11.nc
# -D > 3 - debug level
#ncap2 --cnk_dmn Time,1 -s 'Temp[Time,Layer,lath,lonh]=pt_inc' tmp1.nc tmp11.nc
#ncap2 -6 -s 'Temp[Time,Layer,lath,lonh]=pt_inc' tmp1.nc tmp11.nc
#ncwa -a Time tmp1.nc tmp11.nc
#ncrcat --no_tmp_fl ${DRIN}/${fincr1} ${DRIN}/${fincr2} ${DROUT}/${fincrout}
#ncatted -O -a units,time,m,c,"seconds since 1970-01-01 00:00:00.0" out.nc out2.nc

exit 0


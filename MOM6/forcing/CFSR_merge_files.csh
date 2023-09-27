
setenv Y 2000
setenv M 01

set rec = 1
foreach d(`ls -1 cfsr.${Y}${M}????.nc`)
setenv f `basename ${d} .nc`
ncks --mk_rec_dmn time ${d} ${f}_${rec}.nc
echo ${f}
echo ${f}_${rec}
@ rec += 1
end
ncrcat cfsr.*_*.nc out.nc
ncatted -O -a units,time,m,c,"seconds since 1970-01-01 00:00:00.0" out.nc out2.nc
mv -f out2.nc out.nc




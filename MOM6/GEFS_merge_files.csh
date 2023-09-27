#!/bin/csh 

setenv Y 2000
setenv Y2 2001

set rec = 1
foreach d(`ls -1 gefs.${Y}??????.nc gefs.${Y2}010100.nc`)
setenv f `basename ${d} .nc`
ncks --mk_rec_dmn time ${d} ${f}_${rec}.nc
echo ${f}
echo ${f}_${rec}
@ rec += 1
end
ncrcat gefs.??????????_*.nc out.nc


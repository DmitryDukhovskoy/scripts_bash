function ncvarlst { ncks --trd -m ${1} | grep -E ': type' | cut -f 1 -d ' ' | sed 's/://' | sort ; }

usage:
ncvarlst ocean_annual.nc  

produces a list of variables in the netcdf file 


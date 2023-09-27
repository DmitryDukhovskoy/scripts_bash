#! /bin/sh -x
set -u

/bin/rm -f PET*LogFile *.log 

mkdir -pv log

dstmp=`date +%Y%m%d`

for fl in $(ls logfile*.out)
do
  /bin/mv -f $fl log/${fl}-${dstmp}
done

for fl in mediator.log atm.log ESMF_Profile.summary job_timestamp.txt err out
do
  /bin/mv -f $fl log/${fl}-${dstmp}
done

/bin/mv -f core log/.

exit 0

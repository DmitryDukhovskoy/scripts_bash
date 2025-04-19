#!/bin/bash
# usage: check_diff.sh file_name.F90
set -u

export R=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/src/mom6/src/SIS2/src
export D=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/mom6_sis2_irelax/MOM6-examples/src/SIS2/src

if [[ $# < 1 ]]; then
  echo "provide file name to compare"
  exit 5
fi

fl=$1
diff $D/$fl $R/$fl

exit 0



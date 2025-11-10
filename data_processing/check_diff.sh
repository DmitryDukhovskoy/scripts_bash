#!/bin/bash
# usage: check_diff.sh file_name.F90
set -u

export R=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS/ufs_datm_mx025_expt01
export D=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS/ufs_datm_mx025_cold

if [[ $# < 1 ]]; then
  echo "provide file name to compare"
  exit 5
fi

fl=$1
diff $D/$fl $R/$fl

exit 0



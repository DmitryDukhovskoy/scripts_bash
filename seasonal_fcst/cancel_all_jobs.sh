#!/bin/sh
#
# cancel all running slurm jobs 
# usage ./cancel_all_jobs.sh 8859 <--- first N digits of the jobs to be cancelled
# e.g.
#88594278    es       rdtn_c5    normal      Dmitry.Dukhovskoy   PENDING  16:00:00    1      NEPphys_frcst_climOB
#88594133    es       rdtn_c5    normal      Dmitry.Dukhovskoy   PENDING  16:00:00    1      NEPphys_frcst_climOB
#88593750    es       rdtn_c5    normal      Dmitry.Dukhovskoy   PENDING  16:00:00    1      NEPphys_frcst_climOB
#88593659    es       rdtn_c5    normal      Dmitry.Dukhovskoy   PENDING  16:00:00    1      NEPphys_frcst_climOB
set -u

jobid=$1 
squeue -u $USER | grep ^${jobid} | awk '{print $1}' | xargs -n 1 scancel

exit 0

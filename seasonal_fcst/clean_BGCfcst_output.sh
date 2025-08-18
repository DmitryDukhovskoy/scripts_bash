#!/bin/bash
#
# Clean output fields from old runs
# BGC seasonal forecasts
# 
set -u

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] [--ens 1,...,10] ..."
  echo "  --ys     start with this year  <-- Required" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default (1,...,10)"
  echo "  --arch   >0 - remove archive history files, log dir, and restart, =0 - restart only"
  exit 1
}

export OUTDIR=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/forecast_bgc
export EXPT=NEPbgc_fcst_dailyOB
export expt_nmb=01

MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
YR1=0
YR2=0
M1=0
ens1=0
rm_arch=0

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YR1=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --ye)
      YR2=$2
      shift 2
      ;;
    --mm)
      MONTHS=($2)
      shift 2
      ;;
    --ens)
      ENSMB=($2)
      shift 2
      ;;
    --arch)
      rm_arch=$2
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

if [[ $YR1 -eq 0 ]]; then
  echo "ERR: YR1 was not specified $YR1"
  usage
fi
if [[ $YR2 -eq 0 ]]; then
  YR2=$YR1
fi

expt_name=${EXPT}${expt_nmb}

if [[ $rm_arch -eq 0 ]]; then
  echo "Removing restarts for ${YR1} - ${YR2} MM=${MONTHS[@]} ens=${ENSMB[@]}"
else
  echo "Removing restarts and archives for ${YR1} - ${YR2} MM=${MONTHS[@]} ens=${ENSMB[@]}"
fi

cd $OUTDIR
pwd
aa=$( du -h --max-depth=1 . | tail -1 )
nsize=$( echo $aa | cut -d' ' -f1 )
echo "Occupied storage ${nsize}"
date

for (( yr=YR1; yr<=YR2; yr++ )); do
  for ens_run in "${ENSMB[@]}"; do
    for mo in "${MONTHS[@]}"; do
      echo " "
      MM=$( printf "%02d" "$mo" )
      ens=$( printf "%02d" "$ens_run" )
      drnm="${expt_name}_${yr}-${MM}-e${ens}/ncrc6.intel23-repro/archive/restart"
      dirrest="${OUTDIR}/${drnm}"

      # Remove restarts
      if [ -d "$dirrest" ]; then
        echo "Removing  restart files in  $dirrest"
        /bin/rm -rf "$dirrest"/*.tar
      else
        echo "Does not exist: $dirrest"
      fi


      # Remove archived history file if it exists and rm_arch > 0
      # Leave *.nc.tar.ok files for checking finished runs
      drnm="${expt_name}_${yr}-${MM}-e${ens}/ncrc6.intel23-repro/archive"
      dirarch="${OUTDIR}/${drnm}"
      flarch="${yr}${MM}01.nc.tar"
      if [[ ${rm_arch} -gt 0 ]]; then
        if [[ -f "$dirarch/history/$flarch" ]]; then
          echo "Removing $dirarch/history/$flarch"
          /bin/rm -f "$dirarch/history/$flarch"
        else
          echo "Does not exist: $dirarch/history/$flarch"
        fi

        # Also clean stdout dir with logs
        dirlog="${OUTDIR}/${expt_name}_${yr}-${MM}-e${ens}/ncrc6.intel23-repro/stdout"
        if [[ -d "$dirlog" ]]; then
          echo "Removing log files in $dirlog"
          /bin/rm -rf "$dirlog"/run
        else
          echo "Does not exist: $dirlog"
        fi

        # Clean ascii 
        dirascii="${OUTDIR}/${expt_name}_${yr}-${MM}-e${ens}/ncrc6.intel23-repro/archive/ascii"
        if [[ -d "$dirascii" ]]; then
          echo "Removing files in $dirascii"
          /bin/rm -rf "$dirascii"/*.ascii_out.tar
        else
          echo "Does not exist: $dirascii"
        fi

        dirascii="${OUTDIR}/${expt_name}_${yr}-${MM}-e${ens}/ncrc6.intel23-repro/archive_crash"
        if [[ -d "$dirascii" ]]; then
          echo "Removing $dirascii"
          /bin/rm -rf "$dirascii"
        fi
      fi

    done
  done
done


aa=$( du -h --max-depth=1 . | tail -1 )
nsize=$( echo $aa | cut -d' ' -f1 )
echo "After cleaning, occupied storage ${nsize}"
date

  
echo "       "
echo " All Done "

exit 0 


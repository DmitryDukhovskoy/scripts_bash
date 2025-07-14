#!/bin/bash
#
# Copy output fields to gaea 
# For cases when transfer was interrupted
#
# usage: ./gcp_fcst_output.sh YR MM [ens1] [ens2] 
#
set -u

# dir on Gaea
export EXPT=NEPbgc_nudged_hindcast
export PLTF=ncrc5.intel23-repro
export GPLTF=gfdl.${PLTF}
export expt_nmb=01
export expt_name=${EXPT}${expt_nmb}
export OUTDIR=/gpfs/f5/cefi/scratch/${USER}/work/${expt_name}.o135497833
export RDIR=/archive/${USER}/fre/NEP/hindcast_bgc/${GPLTF}/${expt_name}  # PPAN
#export expt_nmb=""

usage() {
  echo "Usage: $0 --yr <year> --mm <month>"
  echo "  --yr    Initialization year of the forecast"
  echo "  --mm    Initialization month of the run (1–12)"
  exit 1
}

if [[ $# -lt 2 ]]; then
  echo " Start year  and month are missing"
  usage
fi

# input with key arguments:
# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yr)
      YR=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --mm)
      M1=$2
      shift 2
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

MM=$( echo $M1 | awk '{printf("%02d", $1)}' )
date_prfx=${YR}${MM}01

cd "$OUTDIR" || { echo "Cannot cd to $OUTDIR"; exit 1; }
pwd

# Check the date is correct:
# see if any files exist with this time stamp
if compgen -G "${date_prfx}*.nc" > /dev/null; then
  echo "Files exist for $date_prfx, the date is ok"
else
  echo "Check date ${date_prfx}, no files found, STOPPING ..."
  exit 1
fi

# Process restart:
# Note: use restart date in dir/file naming not
# the initial date
cd RESTART
nfls=$( ls -1 *res* | wc -l )
if [[ $nfls -eq 0 ]]; then
  echo " no restart files in $OUTDIR/RESTART ... "
else
  date_rest=$(date -d "${date_prfx} +3 months" +%Y%m%d)
  echo "init date: ${date_prfx} --> restart date: ${date_rst}"
  for fll in $( ls *res* ); do
    DRST=${RDIR}/restart/restdate_${date_rest}
    echo "sending $fll ---> $DRST"
    echo "Check dirs for resrtart"

    exit 5     # The script has not been tested - make sure dir names and dates are correct 


    gcp -cd $fll gfdl:$DRST/.
  done
fi

# Process archive output:
cd $OUTDIR
nfls=$( ls -1 ${date_prfx}.*.nc | wc -l )
if [[ $nfls -eq 0 ]]; then
  echo " no output files in $OUTDIR ... "
else
  for fll in $( ls *res* ); do
    DARCH=${RDIR}/history/${date_prfx}
    echo "sending $fll ---> $DARCH"
    gcp -cd $fll gfdl:$DARCH/.
  done
fi

# Process ascii
cd $OUTDIR
DASCII=${RDIR}/ascii/${date_prfx}
for fll in *fms.out *parameter* *.o* *input* diag_table; do
  [[ -f "$fll" ]] || continue
  echo "sending $fll ---> $DASCII"
  gcp -cd "$fll" gfdl:"$DASCII"/.
done

cd $OUTDIR/INPUT
for fll in *_input *_override; do 
  [[ -f "$fll" ]] || continue
  DASCII=${RDIR}/ascii/${date_prfx}
  echo "sending $fll ---> $DASCII"
  gcp -cd $fll gfdl:$DASCII/.
done
  
echo " All Done "

exit 0 


#!/bin/bash 
#  
# The MOM6-SIS2 executable should be created first, e.g.:
# in XML dir: see NEP_BGC_nudged_irlx_hindcast.xml
# I use same executable both for hindcasts and forecasts 
# Not recommended to clone new versions of MOM6-SIS2-COBLAT codes during the hindcast/forecsts
# 
# Use xml template to generate an XML for specific forecast
#
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DSRC=/ncrc/home1/Dmitry.Dukhovskoy/scripts/seasonal_fcst
export DXML=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=${DXML}/xml_bgc
export DARCH=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/forecast_bgc
export PLTF=ncrc6.intel23-repro
export XMLTMP=NEPbgc_seasfcstIrlx_dailyOB_tmplt.xml

# Set defaults:
export expt_nmb=01   # expt 01 - 1st set of BGC f/casts with irlx
export ystart=0      # year to start the f/cast
export MONTHS=(1 4 7 10) # initialization months
export ENSMB=(1 2 3 4 5 6 7 8 9 10)   # ens runs
export irlx_rate=24  # strongest relaxation in the domain, hrs - relaxation rate to use in f/casts
export ensS=0
export ensE=0

# Function to print usage message
usage() {
  echo "Usage: $0 --exptn 3 [--ensn 4] [--ms 7] [--irlx 12] "
  echo "  --exptn   experiment number, default: ${expt_nmb}"
  echo "  --ys      year to start the f/cast, required" 
  echo "  --ms      month to start the f/cast, default: 1,4,7,10" 
  echo "  --ensS    1st ensemble # to run, default: all ensmbls: 1, ..., 10"
  echo "  --ensE    last ensemble number to run, f/cast will be run for ensS,...,ensE, default=ensS"
  echo "  --irlx    max relaxation hours (e.g. 24), irlx=0 - no ice relax, default: ${irlx_rate}"
  exit 1
}

# Pars flags for optional arguments:
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      ystart="$2"
      shift 2
      ;;
    --exptn)
      expt_nmb="$2"
      shift 2
      ;;
    --ms)
      MONTHS=("$2")
      shift 2
      ;;
    --ensS)
      ensS=2
      shift 2
      ;;
    --ensE)
      ensE=2
      shift 2
      ;;
    --irlx)
      irlx_rate="$2"
      shift 2
      ;;
    *)
      echo "Error: Unrecognized option $1"
      usage
      ;;
  esac
done

if [[ $ystart -eq 0 ]]; then
  echo "ERR: ystart was not specified"
  usage
fi

if (( ensS > 0 && ensE == 0 )); then
  ensE=$ensS
fi

if (( $ensS > 0 )); then
  ENSMB=()
  for (( ens=$ensS; ens<=$ensE; ens++ )); do
    ENSMB+=("$ens")
  done
fi

expt_nmb=$(printf "%02d" "$expt_nmb")
bnm=$( echo $XMLTMP | cut -d "_" -f-3 )
expt_name=NEPbgc_fcst_dailyOB${expt_nmb}

echo "======================================================================================= "
echo "Seasonal BGC f/casts experiment ${expt_name}"
echo "  Init year:     ${ystart}"
echo "  Init months:   ${MONTHS[@]}"
echo "  Ens. runs:     ${ENSMB[@]}"
echo "  ice rlx time:  ${irlx_rate}"  


cd $DOUT
for mstart in ${MONTHS[@]}; do
  if [[ $ystart -eq 1993 && $mstart -eq 1 ]]; then
    echo "Skipping month $mstart for $ystart as the 1st start month is April in 1993"
    continue
  fi
  mstart=$(printf "%02d" "$mstart")

  for ens in ${ENSMB[@]}; do
    echo "  "
    echo "Preparing run for $ystart month=$mstart ens=$ens"
    ens0=$(printf "%02d" "$ens") 
    ens_spear=$ens0               # SPEAR ens run for atm. forcing and OBCs

# Check if the run exists, do not rerun:
    dir_arch=$DARCH/${expt_name}_${ystart}-${mstart}-e${ens}/${PLTF}/archive/history
    fltar=${ystart}${mstart}01.nc.tar
    if [ -d $dir_arch ] && [ -s $dir_arch/${fltar} ]; then
      echo "Run already finished: $dir_arch/${fltar}"
      echo " Skipping ..."
      continue
    fi

# Create XML's 
    flxml=${bnm}_${ystart}_${mstart}_e${ens0}.xml
    /bin/rm -f $flxml
    $DSRC/create_BGCseasfcst_dailyOB_xml.sh --ys $ystart --ms $mstart --ens $ens0 --flxml $flxml\
                                 --expt_name $expt_name --xmltmp $XMLTMP --irlx $irlx_rate
    status=$?
    if [[ $status -ne 0 ]]; then
      echo "ERR from create_BGCseasfcst_dailyOB_xml.sh, quitting ..."
      exit 5
    fi
    if [[ ! -s "$flxml" ]]; then 
      pwd
      ls -l
      echo "$flxml not generated - quitting"
      exit 5
    fi

    echo "Submitting f/cast run ${flxml} ..."
    frerun -s -x ${flxml} -p ncrc6.intel23 -t repro ${expt_name}_${ystart}-${mstart}-e${ens0} --overwrite

  done
done

exit 0

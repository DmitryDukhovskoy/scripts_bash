#!/bin/bash
#
# Untar atmospheric SPEAR subset fields 
# prepared on PPANLS
#
#
set -u

DATM=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos

MONTHS=(1 4 7 10) # initialization months
ENSMB=(1 2 3 4 5 6 7 8 9 10)   # ens runs
FS=6    # File system on Gaea
YR1=0
YR2=0
ensS=0
ensE=0

usage() {
  echo "Usage: $0 --ys 1994 --ye 1994"
  echo "  --ys          start with this init year to pprcs the f/cast <-- Required" 
  echo "  --ye          end with this f/cast init year, default=same as ys"
  echo "  --ms      month to start the f/cast, default: 1,4,7,10" 
  echo "  --ensS    1st ensemble # to run, default: all ensmbls: 1, ..., 10"
  echo "  --ensE    last ensemble number to run, f/cast will be run for ensS,...,ensE, default=ensS"
  echo "  --fs      File system on Gaea: 5 or 6, default=6"
  exit 1
}

# Pars flags for optional arguments:
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YR1="$2"
      shift 2
      ;;
    --ye)
      YR2="$2"
      shift 2
      ;;
    --ms)
      MONTHS=("$2")
      shift 2
      ;;
    --ensS)
      ensS=$2
      shift 2
      ;;
    --ensE)
      ensE=$2
      shift 2
      ;;
    --fs)
      FS="$2"
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

if [[ ${YR1} -eq 0 ]]; then
  echo "ERR: Start year was not specified"
  usage
fi

if [[ ${YR2} -eq 0 ]]; then
  YR2="$YR1"
fi

if (( ensS > 0 && ensE == 0 )); then
  ensE=$ensS
fi

if (( ensS > 0 )); then
  ENSMB=()
  for (( ens=$ensS; ens<=$ensE; ens++ )); do
    ENSMB+=("$ens")
  done
fi

if (( FS != 5 && FS != 6 )); then
  echo "ERROR: FS=$FS should be 5 or 6"
  usage
fi

if [[ $FS -eq 5 ]]; then
  DGAEA=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos
else
  DGAEA=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/atmos
fi

cd $DATM || { echo "Error: Cannot cd to $DATM"; exit 1; }
pwd

for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for mo in ${MONTHS[@]}; do
    mo0=$(printf "%02d" "$mo")
    for ens in ${ENSMB[@]}; do
      ens0=$(printf "%02d" "$ens")

      #ftar=spear_atmos_${yr}${mo0}.tar.gz
      ftar=spear_atmos_${yr}${mo0}e${ens0}.tar

      echo "Untarring $ftar"
      tar -xvf $ftar

      status=$?
      if [[ $status == 0 ]]; then
        echo "Removing $ftar"
        /bin/rm $ftar
      fi
    done
  done
done

exit 0

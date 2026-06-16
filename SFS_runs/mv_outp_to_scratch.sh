#!/bin/bash
#
# move MOM6 and CICE6 output of UFS runs 
# from running dir to scratch on gaea
#
set -u

run_name=ufs_datm_mx025

usage() {
  echo "Usage: $0 --ys 1994 --expt 1,..., --socn 0, --sparam 0, --srest 0]"
  echo "  --ys     run year, default: 2025" 
  echo "  --expt   expt number = 1, ... "
  echo "  --socn   =1: save ocean output, =0 - no, default=1"
  echo "  --sice   =1: save ice output, =0 - no, default=1"
  echo "  --sparam =1: save parameter files, =0 - no, default=1"
  echo "  --srest  =1: save ice/ocean restart files, =0 - no, default=1"
  echo "  --sinit  =1: save init ice fields if exist, =0 -no, default=1"
  exit 1
}


# Default values:
fsfx='iceh'
jobnm='datm_mx025' # job name in sbatch submit script
save_param=1  # save parameters and logs from the run  
save_ocn=1    # save ocean output
save_rest=1   # save ice/ocean restarts
save_ice=1    # save CICE output
save_init=1   # save initial CICE fields if these have been dumped
expt_nmb=0
YS=2025          # year of the run

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      YS=$2
      shift 2 
      ;;
    --expt)
      expt_nmb=$2
      shift 2
      ;;
    --sice)
      save_ice=$2
      shift 2
      ;;
    --socn)
      save_ocn=$2
      shift 2
      ;;
    --sparam)
      save_param=$2
      shift 2
      ;;
    --srest)
      save_rest=$2
      shift 2
      ;;
    --sinit)
      save_init=$2
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

if [[ $YS -eq 0 ]]; then
  echo "ERR: YS not defined"
  usage
fi

if [[ ${expt_nmb} -eq 0 ]]; then
  echo "ERR: expt not defined"
  usage
fi

echo "Saving flags: "
echo "  save_ice   = ${save_ice}"
echo "  save_ocn   = ${save_ocn}"
echo "  save_param = ${save_param}"
echo "  save_rest  = ${save_rest}" 
echo "  save_init  = ${save_init}"


syst=$(hostname)
if [[ ${syst:0:4} != "gaea" ]]; then
  echo "ERR: Update directories for ${syst}, default=gaea"
  exit 1
fi

echo "Experiment Number: $expt_nmb"

expt_nmb0=$( printf "%02d" $expt_nmb)
RUNDIR=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS/ufs_datm_mx025_v02
ARCHDIR=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/ufs_datm_mx025/expt${expt_nmb0}

if [ -d "$ARCHDIR" ]; then
  echo "Experiment already exists: ${ARCHDIR}"
  read -p "Do you want to overwrite it? [y/N]: " answer

  case "$answer" in
    [yY]|[yY][eE][sS])
      echo "Overwriting ${ARCHDIR}..."
      rm -rf "$ARCHDIR"
      ;;
    *)
      echo "Quitting."
      exit 5
      ;;
  esac
fi

mkdir -pv $ARCHDIR

cd "$RUNDIR" || { echo "ERROR: Cannot cd to $RUNDIR"; exit 1; }
pwd

echo "Processing CICE output ..."
if [[ "$save_ice" -eq 1 ]]; then
  echo "Moving CICE output --> ${ARCHDIR}/cice6"
  mkdir -pv $ARCHDIR/cice6

  # Check if there are any cice6 files to move
  cd "${RUNDIR}/CICE_OUTPUT" || {
    echo "ERROR: Cannot cd to ${RUNDIR}/CICE_OUTPUT"
    exit 1
  }

  shopt -s nullglob
  cice_files=(iceh.*.nc)
  shopt -u nullglob

  if (( ${#cice_files[@]} == 0 )); then
    echo "No CICE output files found — skipping move."
  else
    echo "Cleaning old files in ${ARCHDIR}/cice6"
    rm -f "${ARCHDIR}/cice6"/*.nc 2>/dev/null

    for fl in "${cice_files[@]}"; do
      echo "Moving $fl --> ${ARCHDIR}/cice6"
      mv -f "$fl" "${ARCHDIR}/cice6"/
    done
  fi

fi

cd "$RUNDIR" || { echo "ERROR: Cannot cd to $RUNDIR"; exit 1; }
if [[ "$save_init" -eq 1 ]]; then
  echo "Processing  CICE init fields"
  cd "${RUNDIR}/CICE_OUTPUT" || {
    echo "ERROR: Cannot cd to ${RUNDIR}/CICE_OUTPUT"
    exit 1
  }

  shopt -s nullglob
  cice_files=(iceh_ic.*.nc)
  shopt -u nullglob

  if (( ${#cice_files[@]} == 0 )); then
    echo "CICE init file not found — skipping move"
  else
    for fl in "${cice_files[@]}"; do
      echo "Moving $fl --> ${ARCHDIR}/cice6"
      mv -f "$fl" "${ARCHDIR}/cice6"/
    done
  fi

fi

echo " "
cd $RUNDIR
pwd
if [[ "$save_param" -eq 1 ]]; then
  echo "Copying log/param files --> $ARCHDIR/params_logs"
  mkdir -pv $ARCHDIR/params_logs 

  param_files=(datm_in datm.streams diag_table err ice_in input.nml \
               model_configure ufs.configure ice_diag.d)


  if (( ${#param_files[@]} == 0 )); then
    echo "No parameter files found in ${RUNDIR} — skipping param save."
  else
    echo "Cleaning ${ARCHDIR}/params_logs"
    rm -f "${ARCHDIR}/params_logs"/*

    for fl in "${param_files[@]}"; do
      if [[ -f "$fl" ]]; then
        echo "Copying $fl --> ${ARCHDIR}/params_logs"
        cp -f "$fl" "${ARCHDIR}/params_logs"/
      fi
    done
  fi

  # Move logs and job outputs
  echo "Moving log files --> ${ARCHDIR}/params_logs"
  mv -f ./*.log "${ARCHDIR}/params_logs"/ 2>/dev/null
  mv -f "${jobnm}.o"* "${ARCHDIR}/params_logs"/ 2>/dev/null

  # Save selected PET logs (mediator, ocean, ice)
  echo "Moving PET log files ..."
  for pet in PET000 PET100 PET200; do
    if [[ -f ${pet}.ESMF_LogFile ]]; then
      mv -f "${pet}.ESMF_LogFile" "${ARCHDIR}/params_logs"/
    fi
  done

  # Remove remaining PET logs
  rm -f PET???.ESMF_LogFile

  # Copy MOM inputs (if exist)
  for momfile in MOM_input MOM_override; do
    if [[ -f INPUT/${momfile} ]]; then
      cp -f "INPUT/${momfile}" "${ARCHDIR}/params_logs"/
    fi
  done

fi

#  Save MOM6 output 
if [[ "$save_ocn" -eq 1 ]]; then
  echo "Saving MOM6 output ..."
  mkdir -pv "${ARCHDIR}/mom6"

  shopt -s nullglob
  mom_files=(ocean_${YS}_??_*.nc)
  shopt -u nullglob

  if (( ${#mom_files[@]} == 0 )); then
    echo "No MOM6 output files found in ${RUNDIR} — skipping move."
  else
    echo "Cleaning old files in ${ARCHDIR}/mom6"
    rm -f "${ARCHDIR}/mom6"/*.nc 2>/dev/null

    for fl in "${mom_files[@]}"; do
      echo "Moving $fl --> ${ARCHDIR}/mom6"
      mv -f "$fl" "${ARCHDIR}/mom6"/
    done

    # Grid file
    mv -f ocean_static.nc "${ARCHDIR}/mom6"/
  fi
fi


if [[ $save_rest -eq 1 ]]; then
  echo " Moving restarts "
  mkdir -pv $ARCHDIR/restart

  if [[ ! -d "${RUNDIR}/RESTART" ]]; then
    echo "WARNING: ${RUNDIR}/RESTART not found. Skipping restart move."
    exit 0
  fi

  cd "${RUNDIR}/RESTART" || {
    echo "ERROR: Failed to cd into ${RUNDIR}/RESTART"
    exit 1
  }

  # Check if there are any restart files to move
  shopt -s nullglob
  fdatm=(DATM_GFS.cpl.r.*.nc)
  tstmp="${fdatm##*.r.}"
  tstmp="${tstmp%.nc}"

  if [ -f ../DATM_GFS.datm.r.${tstmp}.nc ]; then
    mv -f ../DATM_GFS.datm.r.${tstmp}.nc .
  fi

  restart_files=(*.MOM.res*.nc cice_model.res.*.nc DATM_GFS.cpl.r.*.nc)
  shopt -u nullglob

  if (( ${#restart_files[@]} == 0 )); then
    echo "No restart files found in ${RUNDIR}/RESTART — skipping cleanup."
    exit 0
  fi

  rm -rf $ARCHDIR/restart/*.nc
  for fl in "${restart_files[@]}"; do
    echo "Moving $fl --> ${ARCHDIR}/restart"
    mv -f "$fl" "${ARCHDIR}/restart"/
  done

  echo "Restart files moved successfully."
fi


# INPUT files:
mkdir -pv "${ARCHDIR}/params_logs"
ls -la INPUT/* > INPUT_expt${expt_nmb}.log
mv -f "${pet}.ESMF_LogFile" "${ARCHDIR}/params_logs"/


echo "All done"
exit 0



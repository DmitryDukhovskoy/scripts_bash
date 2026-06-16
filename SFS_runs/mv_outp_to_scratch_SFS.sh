#!/bin/bash
#
# move MOM6 and CICE6 output of UFS runs 
# from running dir to scratch on gaea
# SFS CICE experiments
#
set -u

run_name=ufs_datm_mx025

# Default values:
#jobnm='sfs_mx025_c192' # job name in sbatch submit script
jobnm='sfsC192mx025'
save_param=1
save_ocn=1
save_rest=0
save_ice=1
save_init=1
save_atm=1
save_atmnc=0  # netcdf files replicate Grib files
expt_nmb=0
YS=2025

sfxo="oceanm"
sfxi="iceh"
#sfxi="iceh_inst"  # instanteneous output

RUNDIR="/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS/sfs_C192mx025_run2"
rdir=0   # 0=current dir, 1=use RUNDIR

DICE="${RUNDIR}/history"

usage() {
  cat <<EOF
Usage:
  $0 --expt N [options]

Required:
  --expt N        Experiment number

Optional:
  --ys YEAR       Run year (default: ${YS})
  --rdir 0|1      0 = current dir, 1 = use RUNDIR (default: ${rdir})

  --socn 0|1      Save ocean output (default: ${save_ocn})
  --sice 0|1      Save ice output (default: ${save_ice})
  --satm 0|1      Save atmosphere GRIB output (default: ${save_atm})
  --satmnc 0|1    Save atmosphere netcdf output (default: ${save_atmnc})
  --srest 0|1     Save restarts (default: ${save_rest})
  --sinit 0|1     Save initial ice fields (default: ${save_init})
  --sparam 0|1    Save logs/parameters (default: ${save_param})
  --sfxi          Sufix in the CICE6 output name sfxi.YYYY-MM-DD*nc

Example:
  $0 --expt 1 --ys 2022 --socn 0 --sice 1
EOF
  exit 1
}


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
    --rdir)
      rdir="$2"
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
    --satm)
      save_atm=$2
      shift 2
      ;;
    --satmnc)
      save_atmnc=$2
      shift 2
      ;;
    --sfxi)
      sfxi=$2
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

if [[ "$rdir" -eq 0 ]]; then
  RUNDIR="$(pwd)"
fi

echo "Saving flags: "
echo "  save_ice   = ${save_ice}"
echo "  save_ocn   = ${save_ocn}"
echo "  save_param = ${save_param}"
echo "  save_rest  = ${save_rest}" 
echo "  save_init  = ${save_init}"
echo "  save_atm   = ${save_atm}"
echo "  RUNDIR     = ${RUNDIR}"

syst=$(hostname)
if [[ ${syst:0:4} != "gaea" ]]; then
  echo "ERR: Update directories for ${syst}, default=gaea"
  exit 1
fi

echo "Experiment Number: $expt_nmb"

DICE=${RUNDIR}/history  # CICE6 output dir
expt_nmb0=$( printf "%02d" $expt_nmb)
ARCHDIR=/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/sfs_C192mx025_cice_test/expt${expt_nmb0}

echo "RUNDIR $RUNDIR"

if [[ -d "$ARCHDIR" ]]; then
  echo
  echo "WARNING: proceeding may overwrite files"
  read -p "Add missing / Overwrite existing files [y], delete directory [d], or quit [n]? " answer

  case "$answer" in
    [yY]|[yY][eE][sS])
      echo "Overwriting / adding files to ${ARCHDIR}..."
      ;;
    [dD])
      echo "Removing existing ${ARCHDIR} ..."
      if [[ -n "$ARCHDIR" && "$ARCHDIR" != "/" ]]; then
        rm -rf "$ARCHDIR"
      else
        echo "ERROR: ARCHDIR is unsafe: '$ARCHDIR'"
        exit 6
      fi
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
  cd "${DICE}" || {
    echo "ERROR: Cannot cd to ${DICE}"
    exit 1
  }
  pwd

  shopt -s nullglob
  cice_files=(${sfxi}.*.nc)
  shopt -u nullglob

  if (( ${#cice_files[@]} == 0 )); then
    echo "No CICE output files found — skipping move."
  else
    #echo "Cleaning old files in ${ARCHDIR}/cice6"
    #rm -f "${ARCHDIR}/cice6"/*.nc 2>/dev/null

    for fl in "${cice_files[@]}"; do
      echo "Moving $fl --> ${ARCHDIR}/cice6"
      mv -f "$fl" "${ARCHDIR}/cice6"/
    done
  fi

fi

cd "$RUNDIR" || { echo "ERROR: Cannot cd to $RUNDIR"; exit 1; }
if [[ "$save_init" -eq 1 ]]; then
  echo "Processing  CICE init fields"
  cd "${DICE}" || {
    echo "ERROR: Cannot cd to ${DICE}"
    exit 1
  }

  shopt -s nullglob
  cice_files=(iceh_ic.*.nc)  # initial ice conditions
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

  param_files=(datm_in diag_table err ice_in input.nml \
               model_configure ufs.configure ice_diag.d)


  if (( ${#param_files[@]} == 0 )); then
    echo "WARNING: No parameter files found in ${RUNDIR}"
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
  mv -f ./log.* "${ARCHDIR}/params_logs"/ 2>/dev/null
  mv -f "${jobnm}.o"* "${ARCHDIR}/params_logs"/ 2>/dev/null

  # if all logs are moved into logs.jXXXXX - move the whole dir
  shopt -s nullglob
  dirs=(logs.j*/)
  if [ ${#dirs[@]} -gt 0 ]; then
    echo "Logs directory found, moving to ${ARCHDIR}/params_logs"
    mv -f "${dirs[@]}" "${ARCHDIR}/params_logs"/ 2>/dev/null
  fi
  shopt -u nullglob

  # Save selected PET logs (mediator, ocean, ice)
  #echo "Moving PET log files ..."
  #for pet in PET000 PET100 PET200; do
  #  if [[ -f ${pet}.ESMF_LogFile ]]; then
  #    mv -f "${pet}.ESMF_LogFile" "${ARCHDIR}/params_logs"/
  #  fi
  #done

  # Remove remaining PET logs
  #rm -f PET???.ESMF_LogFile

  # Copy MOM inputs (if exist)
  for momfile in MOM_input MOM_override; do
    if [[ -f INPUT/${momfile} ]]; then
      cp -f "INPUT/${momfile}" "${ARCHDIR}/params_logs"/
    fi
  done

  cp -f MOM6_OUTPUT/MOM_parameter_doc.* "${ARCHDIR}/params_logs/" \
    || echo "WARNING: MOM6_OUTPUT/MOM_parameter_doc.* copy failed"

fi

echo "MOM6"
#  Save MOM6 output 
if [[ "$save_ocn" -eq 1 ]]; then
  echo "Saving MOM6 output ..."
  mkdir -pv "${ARCHDIR}/mom6"

  shopt -s nullglob
  mom_files=(${RUNDIR}/${sfxo}_*_??_*.nc)
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
    mv -f ocean_static.nc "${ARCHDIR}/mom6"/ || echo "WARNING: failed to move ocean_static.nc"
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
  #fdatm=(DATM_GFS.cpl.r.*.nc)
  #tstmp="${fdatm##*.r.}"
  #tstmp="${tstmp%.nc}"
  #
  #if [ -f ../DATM_GFS.datm.r.${tstmp}.nc ]; then
  #  mv -f ../DATM_GFS.datm.r.${tstmp}.nc .
  #fi

  restart_files=(*.MOM.res*.nc cice_model.res.*.nc)
  shopt -u nullglob

  if (( ${#restart_files[@]} == 0 )); then
    echo "No MOM6 or CICE6 restart files found in ${RUNDIR}/RESTART — skipping cleanup."
  else
    #rm -rf $ARCHDIR/restart/*.nc
    for fl in "${restart_files[@]}"; do
      echo "Moving $fl --> ${ARCHDIR}/restart"
      mv -f "$fl" "${ARCHDIR}/restart"/
    done

    echo "Restart files moved successfully."
  fi

  # atm. restarts
  # Save the last one if there are > 1
  # Get the latest date & time stamps
  latest_date=$(ls *.nc 2>/dev/null | cut -d. -f1,2 | sort -u | sort | tail -1)
  echo "Moving atm restarts for ${latest_date}"
  mv -f ${latest_date}.* "${ARCHDIR}/restart"/

fi

# Atm data Grib output
cd $RUNDIR
if [[ $save_atm -eq 1 ]]; then
  echo "Saving FV3 atm output ..."
  mkdir -pv "${ARCHDIR}/fv3atm"

  shopt -s nullglob
  files=(GFSFLX.Grb* GFSPRS.Grb*)

  if (( ${#files[@]} )); then
    echo "Moving ${#files[@]} files --> ${ARCHDIR}/fv3atm"
    mv -f "${files[@]}" "${ARCHDIR}/fv3atm"/
  else
    echo "No FV3 atm files found"
  fi
  shopt -u nullglob
fi

# Atm data NetCDF output
cd $RUNDIR
if [[ $save_atmnc -eq 1 ]]; then
  echo "Saving FV3 atm output ..."
  mkdir -pv "${ARCHDIR}/fv3atm"

  shopt -s nullglob
  files=(atmf*.nc sfcf*.nc)

  if (( ${#files[@]} )); then
    echo "Moving ${#files[@]} files --> ${ARCHDIR}/fv3atm"
    mv -f "${files[@]}" "${ARCHDIR}/fv3atm"/
  else
    echo "No FV3 atm files found"
  fi
  shopt -u nullglob
#else
#  echo "Removing atmf*nc and sfcf*nc"
#  rm -f atmf*nc
#  rm -f sfcf*nc
fi

# RUNdir exclude all *nc files:
cd $RUNDIR
RLOG=RUNDIR_expt${expt_nmb}.log
pwd > "$RLOG"
find . ! -name "*.nc" -exec ls -ld {} \; >> "$RLOG"
mv -f "$RLOG" "${ARCHDIR}/params_logs"/

# INPUT files:
cd $RUNDIR
INLOG=INPUT_expt${expt_nmb}.log
mkdir -pv "${ARCHDIR}/params_logs"
ls -la INPUT/* > $INLOG
mv -f "$INLOG" "${ARCHDIR}/params_logs"/

# Change permission:
chmod -R 755 ${ARCHDIR}

echo "All done"
exit 0



#!/bin/bash

# Shared configuration for the ice-thickness ML workflow

DWORK="/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17"
DPYTH="/ncrc/home1/Dmitry.Dukhovskoy/python/ithkn_MLemulator"
PTHYAML="/ncrc/home1/Dmitry.Dukhovskoy/python/ithkn_MLemulator"
PTHDAILY="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/GDAS_T2m/glob/daily_gdas_grid"
PTHPRED="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/ML_emulator_ithkn/predictors"   # ML predictor fields
HOURS=(0 6 12 18)          # ERA5 hourly field used for daily averaging
FLT2M="GDAS_flipN_T2m_"    # daily T2m file name base

# List of dynamic predictors:
PRED=(t2m iconc divUice sst ifdd ihdd)

# Function for checking daily T2m fields created from hourly GDAS:
check_daily_t2m() {
  local rdate="$1"
  local flday="${FLT2M}${rdate}.npy"
  local YR="${rdate:0:4}"
  local PTHF="${PTHDAILY}/${YR}"
  local fullpath="${PTHF}/${flday}"

  if [[ -f "${fullpath}" ]]; then
    echo "Daily T2m exists: ${fullpath}"
    return 0
  else
    echo "Daily T2m does not exist: ${fullpath}"
    return 1
  fi
}

# Function for checking whether a predictor is selected:
find_predictor() {
  local pred_name="$1"
  for var in "${PRED[@]}"; do
    if [[ "$var" == "$pred_name" ]]; then
      echo "Predictor ${pred_name} found"
      return 0
    fi
  done
  echo "Predictor ${pred_name} not used, skipping"
  return 1
}

# Function for selecting GFSv17 stream based on date:
find_gfs_stream() {
  local rdate="$1"

  if [[ "$rdate" -ge 20220830 && "$rdate" -le 20221015 ]]; then
    RUN="retrov17_01_stream1a"
    DROOT="/5year/NCEPDEV/emc-global/emc.glopara/GAEAC6/GFSv17"
  elif [[ "$rdate" -ge 20240301 && "$rdate" -le 20240531 ]]; then
    RUN="retrov17_01_stream1b"
    DROOT="/5year/NCEPDEV/emc-global/emc.glopara/GAEAC6/GFSv17"
  elif [[ "$rdate" -ge 20240601 && "$rdate" -le 20241130 ]]; then
    RUN="retrov17_01_stream2"
    DROOT="/5year/NCEPDEV/emc-global/emc.glopara/WCOSS2/GFSv17"
  elif [[ "$rdate" -ge 20241201 && "$rdate" -le 20250531 ]]; then
    RUN="retrov17_01_stream3"
    DROOT="/5year/NCEPDEV/emc-global/emc.glopara/WCOSS2/GFSv17"
  elif [[ "$rdate" -ge 20250601 && "$rdate" -le 20251130 ]]; then
    RUN="retrov17_01_stream4"
    DROOT="/5year/NCEPDEV/emc-global/emc.glopara/GAEAC6/GFSv17"
  elif [[ "$rdate" -ge 20251201 && "$rdate" -le 20260630 ]]; then
    RUN="retrov17_01_realtime"
    DROOT="/5year/NCEPDEV/emc-global/emc.glopara/WCOSS2/GFSv17"
  else
    echo "ERROR: No GFSv17 stream defined for $rdate" >&2
    return 1
  fi

  echo "Using stream: $RUN"
  return 0
}


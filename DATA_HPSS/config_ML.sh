#!/bin/bash

# Shared configuration for the ice-thickness ML workflow

DWORK="/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17"
DPYTH="/ncrc/home1/Dmitry.Dukhovskoy/python/ithkn_MLemulator"
PTHDAYLY="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/GDAS_T2m/glob/daily_gdas_grid"
PTHPRED="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/ML_emulator_ithkn/predictors"   # ML predictor fields
HOURS=(0 6 12 18)          # ERA5 hourly field used for daily averaging
FLT2M="GDAS_flipN_T2m_"    # daily T2m file name base

# Function for checking daily T2m fields created from hourly GDAS:
check_daily_t2m() {
  local rdate="$1"
  local flday="${FLT2M}${rdate}.npy"
  local YR="${rdate:0:4}"
  local PTHF="${PTHDAYLY}/${YR}"
  local fullpath="${PTHF}/${flday}"

  if [[ -f "${fullpath}" ]]; then
    echo "Daily T2m exists: ${fullpath}"
    return 0
  else
    echo "Daily T2m does not exist: ${fullpath}"
    return 1
  fi
}



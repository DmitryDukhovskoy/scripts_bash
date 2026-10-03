#!/bin/bash
#
#  Check if GDAS  SOCA fields required for ML predictors exist
#  Transfer from HPSS if needed
set -u 

DWORK="/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17"
MLDATA="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/ML_emulator_ithkn/predictors"


usage() {
  echo "Usage: sbatch $0 --rdate 20250101 --dtsat 90 (default) --dtuice 1 (default)"
  echo "  --rdate  required start date YYYYMMDD, e.g. 20250101" 
  echo "  --dtsat  integration days for deriving IFDD and IHDD from SAT (default=90)"
  echo "  --dtuice time averaging (days) for divU ice (default=1)"
  exit 1
}   

construct_icefile() {
  local idate="$1"
  local pthice="${DWORK}/ice.${idate}"
  local flice="${idate}.030000.cice_model.res.nc"

  echo "${pthice}/${flice}"
}

construc_ocnfile(){
  # Find date of the previous day when mom analysis started
  # IAU start date and IAU start hour = -6hr from forecast run
  local odate="$1"
  adate=$(date -d "$rdate - 1 day" +%Y%m%d) || { 
  echo "ERROR: Invalid date: $rdate" 
  exit 1 
  }
  local file_ocean="gdas.t${HRa}z.inst.f006.nc"
  local pthocn="${DWORK}/ocean.${adate}"
  

}

rdate=""
dtsat=90
dtuice=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rdate)
      rdate="$2"
      shift 2
      ;;
    --dtsat)
      dtsat="$2"
      shift 2
      ;;
    --dtuice)
      dtuice="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown option: $1"
      usage
      ;;
  esac
done

if [[ -z "$rdate" ]]; then
  echo "ERROR: --rdate is required"
  usage
fi  

# "PRED": ["yday", "gcoord", "mnithkn", "iconc", "sst", "divu", "frzdays", "heatdays", "sat"]
# Ice conc:
echo "Checking ice restart for ${rdate}"
DFLICE=$(construct_icefile "$rdate")

if [[ ! -f "$DFLICE" ]]; then
  echo "Missing ICE FILE: $DFLICE"
  # transfer from HPSS
  sbatch get_soca_ice_restart.sh --rdate "$rdate"   
fi

# divU, if dtuice>1: average over N days to compute divUice
if [[ "$dtuice" -ge 1 ]]; then
  echo "Checking ice restart for deriving divUice avrg. over $dtuice days"
  sdate=$(date -d "$rdate - $((dtuice-1)) days" +%Y%m%d)
  DAY="$sdate"
  while [[ "$DAY" -le "$rdate" ]]; do
    DFLICE=$(construct_icefile "$DAY")

    if [[ ! -f "$DFLICE" ]]; then
      echo "Missing ICE FILE: $DFLICE"
      # transfer from HPSS
      sbatch get_soca_ice_restart.sh --rdate "$DAY"   
    fi

    DAY=$(date -d "$DAY + 1 days" +%Y%m%d)
  done
fi

# SST from MOM6 analysis
# Find date of the previous day when mom analysis started
# IAU start date and IAU start hour = -6hr from forecast run
# Fhr=6
Tanls=6 
HRa=$((24 - Tanls))              # IAU start hour
HRa=$((HRa % 24))
HRa=$(printf "%02d" "$HRa")
Fhr=$(printf "%03d" "$Tanls")
adate=$(date -d "$rdate - 1 day" +%Y%m%d)
file_ocean="gdas.t${HRa}z.inst.f{Fhr}.nc"
pthocn="${DWORK}/ocean.${adate}"
DFLOCN="${pthocn}/${file_ocean}"

if [[ ! -f "$DFLICE" ]]; then
  echo "Missing MOM6 analysis $DFLOCN"
  # transfer from HPSS
  sbatch get_ocean_anls.sh --rdate "$rdate"
fi

# T2m (SAT) from GDAS
# Need to have all 6hr fields for rdate
# To derive daily mean SAT
HOURS=(0 6 12 18)
pthatm="${DWORK}/gdas.${rdate}"

for HR in "${HOURS[@]}"; do
  HR=$(printf "%02d" "$HR")
  file_gdas="gdas.t${HR}z.sfc.f000.nc"
  DFLATM="${pthatm}/${file_gdas}"

  if [[ ! -f ${DFLATM} ]]; then
    echo "GDAS atm files missing for $rdate : $HR"
    sbatch get_GDASatm.sh --rdate "$rdate" --hr "$HR"
  fi
done

# For deriving IFDD and IHDD
# Need daily field for the integration period at dt time intervals
# Check if IFDD / IHDD files exist for rdate:
#
dt=3    # skipping intervals, days
dxy="050"  # dlt X / dlt Y for ML grid points
intgr_time=90  # days
itm=$(printf "%03d" "$intgr_time")
PTHDAILY="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/GDAS_T2m/glob/daily_gdas_grid"
PTHINT="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/ML_emulator_ithkn/predictors"
flfrz="IFDD_GDAS_${itm}days_dxy${dxy}_${rdate}_${regn}.npz"
flheat="IHDD_GDAS_${itm}days_dxy${dxy}_${rdate}_${regn}.npz"

# Check if IFGG/IHDD fields exist
if [[ ! -f "${PTHINT}/${flfrz}" ||  ! -f "${PTHINT}/${flheat}" ]]; then
  echo "IFDD or IHDD files for ${rdate} are missing, get daily SAT from FV3 GDAS"

  # Start from month day 1
  tmpdate=$(date -d "$rdate -${intgr_time} days" +%Y%m%d) || {
      echo "ERROR: invalid date $rdate"
      exit 1
  }

  sdate="${tmpdate:0:6}01"
  sbatch derive_dailyT2m_Ndays.sh --sdate "$sdate" --edate "$rdate" --dt "$dt"
fi

echo "All Done"

exit 0




#!/bin/bash
#
#  Check if GDAS  SOCA fields required for ML predictors exist
#  Transfer from HPSS if needed
#  Note SST for predictor is used from GDAS
#  To start experiment, need MOM6 restart files, see: get_soca_ocean_restart.sh
#  SST fields need to be modified in the restart file(s) not GDAS
set -u 

Not needed for creating predictors but to run GFS SFS runs need restart fields:
Add transfer of MOM6 restart fields 
Add atm. restart fields

# Load paths, variables for ML
#DWORK="/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/GFSv17"
#HOURS=(0 6 12 18)
source config_ML.sh

rdate=""
#dtsat=90
dtuice=1
regn=""
dtatm=3           # skipping intervals, days for atm. daily fields
dxy=50            # dlt X / dlt Y for ML grid points, corr. length scale
intgr_frz=90      # integration time, days, for deriving IFDD / IHDD


usage() {
  echo "Usage: sbatch $0 --rdate 20250101 --intfrz 90 --dtuice 1 --dxy 50"
  echo "  --rdate  required start date YYYYMMDD, e.g. 20250101" 
  echo "  --regn   region: north (Arctic) or south (Antarctic)"
  echo " Optional: "
  echo "  --intfrz integration days for deriving IFDD and IHDD from SAT (default=90)"
  echo "  --dtuice time averaging (days) for divU ice (default=1)"
  echo "  --dtatm  time skip (days) atm. daily fileds, IFDD / IHDD integration, default=${dtatm}"
  echo "  --dxy    correlation scale for (km) used to derive training grid points, default=${dxy}"
  exit 1
}   

construct_icefile() {
  local idate="$1"
  local pthice="${DWORK}/ice.${idate}"
  local flice="${idate}.030000.cice_model.res.nc"

  echo "${pthice}/${flice}"
}

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
    --regn)
      regn="$2"
      shift 2
      ;;
    --dtatm)
      dtatm="$2"
      shift 2
      ;;
    --dxy)
      dxy="$2"
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

if [[ -z "$regn" ]]; then
  echo "ERROR: --regn is required"
  usage
fi  

dxy=$(printf "%03d" "$dxy")

# Ice conc:
# Needed for deriving divUice, first check the one for rdate
DFLICE=$(construct_icefile "$rdate")
echo "Checking ice restart $DFLICE for ${rdate}"

if [[ ! -f "$DFLICE" ]]; then
  echo "Missing ICE FILE: $DFLICE"
  # transfer from HPSS
  sbatch get_soca_ice_restart.sh --rdate "$rdate"   
else
  echo "   --> ok: exist $DFLICE"
fi

# divU, if dtuice>1: average over N days to compute divUice
if [[ "$dtuice" -ge 1 ]]; then
  echo "Checking ice restart for deriving divUice avrg time= $dtuice days"
  sdate=$(date -d "$rdate - $((dtuice-1)) days" +%Y%m%d)
  DAY="$sdate"
  while [[ "$DAY" -le "$rdate" ]]; do
    DFLICE=$(construct_icefile "$DAY")

    if [[ ! -f "$DFLICE" ]]; then
      echo "Missing ICE FILE: $DFLICE"
      # transfer from HPSS
      sbatch get_soca_ice_restart.sh --rdate "$DAY"   
    else
      echo "   --> ok: exist $DFLICE"
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
adate=$(date -d "$rdate -1 day" +%Y%m%d)
file_ocean="gdas.t${HRa}z.inst.f${Fhr}.nc"
pthocn="${DWORK}/ocean.${adate}"
DFLOCN="${pthocn}/${file_ocean}"

echo "Checking MOM6 anls ${rdate}"
if [[ ! -f "$DFLOCN" ]]; then
  echo "Missing MOM6 analysis $DFLOCN"
  # transfer from HPSS
  sbatch get_ocean_anls.sh --rdate "$rdate"
else
  echo "   --> ok: exist $DFLOCN"
fi

# T2m (SAT) from GDAS
# Need to have all 6hr fields for rdate
# To derive daily mean SAT for rdate, if daily field is missing
pthatm="${DWORK}/gdas.${rdate}"

# Use check function in config_ML.sh to check whether daily T2m exists
if check_daily_t2m "${rdate}"; then
  echo "Daily T2m for $rdate exists, GDAS atm fields are not needed ..."
else
  for hr in "${HOURS[@]}"; do
    HR=$(printf "%02d" "$hr")
    file_gdas="gdas.t${HR}z.sfc.f000.nc"
    DFLATM="${pthatm}/${file_gdas}"

    if [[ ! -f "${DFLATM}" ]]; then
      echo "GDAS atm files missing for $rdate : $HR"
      sbatch get_GDASatm.sh --rdate "$rdate" --hr "$HR"
    fi
  done
fi

# For deriving IFDD and IHDD
# Need daily field for the integration period at dt time intervals
# Check if IFDD / IHDD files exist for rdate:
#
itm=$(printf "%03d" "$intgr_frz")
#PTHDAILY="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/GDAS_T2m/glob/daily_gdas_grid"
#PTHPRED="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/data/ML_emulator_ithkn/predictors"
flfrz="IFDD_GDAS_${itm}days_dxy${dxy}_${rdate}_${regn}.npz"
flheat="IHDD_GDAS_${itm}days_dxy${dxy}_${rdate}_${regn}.npz"

# Check if IFGG/IHDD fields exist
if [[ ! -f "${PTHPRED}/${flfrz}" ||  ! -f "${PTHPRED}/${flheat}" ]]; then
  echo "IFDD or IHDD files for region ${regn}, ${rdate} are missing, get daily SAT from FV3 GDAS"

  # Start from month day 1
  tmpdate=$(date -d "$rdate -${intgr_frz} days" +%Y%m%d) || {
      echo "ERROR: invalid date $rdate"
      exit 1
  }

  sdate="${tmpdate:0:6}01"
  echo "Submitting derive_dailyT2m_Ndays.sh --sdate $sdate --edate $rdate --dt $dtatm"
  sbatch derive_dailyT2m_Ndays.sh --sdate "$sdate" --edate "$rdate" --dt "$dtatm"
else
  echo "Found: IFDD and IHDD for region ${regn}, ${rdate}, GDAS atm. fields not needed"
  echo "${PTHPRED}"
fi

echo "All Done"

exit 0




#!/bin/bash
#
# Check atmospheric forcing, ocean OBC, river runoff files
# for seasonal f/cast with dailyOB 
#
# usage: ./check_forcing_dailyOB.sh YR1 [YR2 ] [M1] [ens1]

#
set -u

usage() {
  echo "Usage: $0 --ys 1994 [--ye 1995] [--mm 4] [--ens 1,...,10] [--fs 5 or 6] [--run bgc or none]"
  echo "  --ys     start with this year  <-- Required" 
  echo "  --ye     end with this year, default=same as ys"
  echo "  --mm     month to process, default (1,4,7,10)"
  echo "  --ens    SPEAR ens. run to process, default (1,...,10)"
  echo "  --fs     FIle system 5 or 6, default 6"
  echo "  --run    bgc to check for BGC OB daily esper files"
  exit 1
}

function report_result {
  local yr=$1
  local MM=$2
  local ens=$3
  local fldnm=$4
  local result=$5
  echo "  ${yr} Months:${MM} ens${ens} ${fldnm} ==>   ${result} "
}

MONTHS=(1 4 7 10)
ENSMB=(1 2 3 4 5 6 7 8 9 10)
YR1=0
YR2=0
M1=0
ens1=0
FS=6
run=none

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
    --fs)
      FS=$2
      shift 2
      ;;
    --run)
      run=$2
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

# File systems:
if [[ $FS -eq 5 ]]; then
  DSCR=/gpfs/f5/cefi/scratch
elif [[ $FS -eq 6 ]]; then
  DSCR=/gpfs/f6/ira-cefi/scratch
else
  echo "Unrecognized fily system $FS"
  exit 5
fi

echo "Checking restart files on Filesystem f${FS}"
export FDIR=$DSCR/Dmitry.Dukhovskoy/NEP_data/forecast_input_data
export obc_dir=$FDIR/obcs_spear_daily
export atm_dir=$FDIR/atmos
export riv_dir=$FDIR/runoff


# atmos data:
echo "Atmospheric forcing:  "
prfx='atmos_daily'
cd ${atm_dir}
pwd
ffound=0
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do 
  for ens_run in ${ENSMB[@]}; do
    for mo in ${MONTHS[@]}; do
      MM=$( echo $mo | awk '{printf("%02d", $1)}' )  
      ens=$( echo $ens_run | awk '{printf("%02d", $1)}' )  
      for drnm in $( ls -d ${yr}-${MM}-e${ens} ); do
        ffound=$(( ffound+=1 ))
        natm=0
        nexpct=8
        for fldnm in lwdn_sfc precip q_ref slp swdn_sfc t_ref u_ref v_ref; do
          if [ -s $drnm/${prfx}*${yr}${MM}01-*${fldnm}.nc ]; then
           natm=$(( natm+=1 ))
          fi
        done

        if [[ 10#$natm -eq 10#$nexpct ]]; then
          report_result $yr $MM $ens '' "ok: ${natm} atm fields"
        else
          report_result $yr $MM $ens '' "!!! MISSING !!! $natm atm fields, expected $nexpct"
       fi

      done
    done
  done
done
  
if [[ $ffound -eq 0 ]]; then
  for MM in ${MONTHS[@]}; do
    report_result $yr $MM $ens1 "all atmospheric fields" '!!! MISSING !!!'
  done
fi

echo "------------------------------------------------------"
echo " " 

echo "Open Boundary Fields:  "
prfx='OBCs_spear_daily_init'
cd ${obc_dir}
pwd
ffound=0
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do 
  for ens_run in ${ENSMB[@]}; do
    ndirs=$( ls -d ${yr}_e${ens} 2>/dev/null | wc -l )
    ens=$( echo $ens_run | awk '{printf("%02d", $1)}' )
#    echo "${yr}_e${ens} $ndirs"
    if [[ $ndirs -eq 0 ]]; then
      for mo in ${MONTHS[@]}; do
        MM=$( echo $mo | awk '{printf("%02d", $1)}' )  
        report_result $yr $MM $ens $prfx '!!! MISSING !!!'
      done
      continue
    fi

    for drnm in $( ls -d ${yr}_e${ens} ); do
      if [ ! -d $drnm ]; then
        echo "$drnm does not exist, no data"
        continue
      fi
      for mo in ${MONTHS[@]}; do
        MM=$( echo $mo | awk '{printf("%02d", $1)}' )  
        if [[ $M1 -gt 0 ]] && [[ 10#$MM -ne 10#$M1 ]]; then
          continue
        fi
        ffound=1
        if [ -s $drnm/${prfx}${yr}${MM}01_e${ens}.nc ]; then
          report_result $yr $MM $ens $prfx 'ok'
        else
          report_result $yr $MM $ens $prfx '!!! MISSING !!!'
        fi
      done
    done
  done
done

echo "------------------------------------------------------"
echo " " 

if [ $run == "bgc" ]; then
  # monthly TA/DIC esper fields prepared for all ensembles from 1 SPEAR ens. run
  echo "Annual ESPER BGC fields:"
  bgcdir=${DSCR}/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/BGC_esper_seasfcst
  cd $bgcdir
  for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
    yr2=$(( yr+1 ))
    flesper=bgc_esper_SPEARmnth_${yr}-${yr2}.nc
    if [ -s $flesper ]; then
      echo "  $yr ${flesper}  ==>      ok"
    else
      echo "$  yr annual ESPER BGC fields       !!! MISSING !!!"
    fi
  done

  echo "------------------------------------------------------"
  echo "   "
fi

#if [[ $ffound -eq 0 ]]; then
#  report_result $yr $M1 $ens1 $prfx '!!! MISSING !!!'
#fi

# Check unzipped OB files:
cd $obc_dir
ngz=$( ls -1 ${prfx}*.gz 2>/dev/null | wc -l )
echo " "
echo "Unzipped / not arranged OB files = $ngz"
if [[ $ngz -gt 0 ]]; then
  for fl in $( ls ${prfx}*.gz ); do
    echo "${obc_dir} -->  ${fl} "
  done
fi


echo "------------------------------------------------------"
echo " " 

echo "River runoff daily fields:  "
#prfx='glofas_runoff_NEP_816x342_daily_'
cd ${riv_dir} || echo "Missing: $riv_dir"
pwd
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
#  ifound=0
  flriv=GLOFASv4_runoff_NEP_816x342_clim_1993-2024.nc
  if [ -s $flriv ]; then
    report_result $yr "1-12" "01-10" $flriv 'ok'
  else
    report_result $yr "1-12" "01-10" $flriv '!!! MISSING !!!'
  fi
# These are daily data, need clim runoff for f/casts
#  for flriv in $( ls ${prfx}????-????.nc ); do
#    dmm=$( echo $flriv | cut -d"." -f1 )
#    rspan=$( echo $dmm | cut -d"_" -f6 )
#    yrS=$( echo $rspan | cut -d"-" -f1 )
#    yrE=$( echo $rspan | cut -d"-" -f2 )
#    if [[ $yr -ge $yrS ]] && [[ $yr -lt $yrE ]]; then
#      report_result $yr "1-12" "01-10" $flriv 'ok'
#      ifound=1
#      break
#    fi
#  done
#  if [[ ifound -eq 0 ]]; then
#    report_result $yr "1-12" "01-10" $prfx '!!! MISSING !!!'
#  fi
done

echo "------------------------------------------------------"
echo " " 

echo "MOM and SIS restart files:"
if [[ $FS -eq 5 ]]; then
  RDIR=${DSCR}/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/restart
else
  RDIR=${DSCR}/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/restart_bgc/seas_fcast
fi
momres=MOM.res.nc
sisres=ice_model.res.nc
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  for mo in ${MONTHS[@]}; do
    MM=$( echo $mo | awk '{printf("%02d", $1)}' )  
    if [[ $FS -eq 5 ]]; then
      rest_dir=${RDIR}/${yr}${MM}
    else
      rest_dir=${RDIR}/restdate_${yr}${MM}01
    fi
    if [[ $FS -eq 5 ]]; then
      if [ -d ${rest_dir} ]; then
        if [ -s ${rest_dir}/${momres} ]; then
          echo "  ${yr}-${MM} MOM restart:        ok"
        else 
          echo "  ${yr}-${MM} MOM restart:        !!! MISSING !!!"
        fi
        if [ -s ${rest_dir}/${sisres} ]; then
          echo "  ${yr}-${MM} SIS2 restart:       ok"
        else 
          echo "  ${yr}-${MM} SIS2 restart:       !!! MISSING !!!"
        fi
      else
        echo "  ${yr}-${MM} MOM restart:        !!! MISSING !!!"
        echo "  ${yr}-${MM} SIS2 restart:       !!! MISSING !!!"
      fi
    else
      cd $rest_dir || { echo "Missing $rest_dir: MOM and SIS restarts MISSING"; continue; }
      nmom_rest=$( ls -1 MOM*${yr}${MM}*res*nc 2>/dev/null | wc -l )
      if [[ $nmom_rest -eq 0 ]]; then
        echo "  ${yr}-${MM} MOM restarts:                  !!! MISSING !!!"
      else
        echo "  ${yr}-${MM} MOM restarts $nmom_rest:               expected 8"
      fi
      nsis_rest=$( ls -1 ice_model*${yr}${MM}*res.nc 2>/dev/null | wc -l )
      if [[ $nsis_rest -eq 0 ]]; then
        echo "  ${yr}-${MM} SIS2 restart:                  !!! MISSING !!!"
      else
        echo "  ${yr}-${MM} SIS2 restart:                  ok"
      fi
      nicob=$( ls -1 ice_cobalt*${yr}${MM}*res.nc 2>/dev/null | wc -l )
      if [[ $nicob -gt 0 ]]; then
        echo "  ${yr}-${MM} ice_cobalt restart:            ok"
      else
        echo "  ${yr}-${MM} ice_cobalt restart:            !!! MISSING !!"
      fi
      nicob=$( ls -1 ocean_cobalt*${yr}${MM}*res.nc 2>/dev/null | wc -l )
      if [[ $nicob -gt 0 ]]; then
        echo "  ${yr}-${MM} ocean_cobalt_airsea restart:   ok"
      else
        echo "  ${yr}-${MM} ocean_cobalt_airsea restart:   !!! MISSING !!"
      fi
      ncplr=$( ls -1 coupler*${yr}${MM}*res 2>/dev/null | wc -l )
      if [[ $ncplr -gt 0 ]]; then
        echo "  ${yr}-${MM} coupler restart:               ok"
      else
        echo "  ${yr}-${MM} coupler restart:               !!! MISSING !!"
      fi

    fi
  done
done

echo "       "

exit 0 


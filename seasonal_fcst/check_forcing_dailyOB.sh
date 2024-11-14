#!/bin/bash
#
# Check atmospheric forcing, ocean OBC, river runoff files
# for seasonal f/cast with dailyOB 
#
# usage: ./check_forcing_dailyOB.sh YR1 [YR2 ] [M1] [ens1]

#
set -u

export FDIR=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data
export obc_dir=$FDIR/obcs_spear_daily
export atm_dir=$FDIR/atmos
export riv_dir=$FDIR/runoff

if [[ $# -lt 1 ]]; then
  echo "usage: ./check_forcing_dailyOB.sh YR1 [YR2 ]"
  echo " Start year is missing"
  exit 1
fi

function report_result {
  local yr=$1
  local MM=$2
  local ens=$3
  local fldnm=$4
  local result=$5
  echo "  ${yr} Months:${MM} ens${ens} ${fldnm} ==>   ${result} "
}


YR1=$1
YR2=$YR1
M1=0
ens1=0
if [[ $# -eq 2 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
  else
    M1=$2
  fi
fi 

if [[ $# -eq 3 ]]; then
  if [[ $2 -gt 100 ]]; then
    YR2=$2
    M1=$3
  else
    M1=$2
    ens1=$3
  fi
fi

# atmos data:
echo "Atmospheric forcing:  "
prfx='atmos_daily'
cd ${atm_dir}
pwd
ffound=0
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do 
  for ens in 01 02 03 04 05 06 07 08 09 10; do
    if [[ $ens1 -gt 0 ]] && [[ ! 10#$ens -eq 10#$ens1 ]]; then
      continue
    fi
    for drnm in $( ls -d ${yr}-??-e${ens} ); do
      MM=$( echo $drnm | cut -d"-" -f2 )
      if [[ $M1 -gt 0 ]] && [[ ! $MM -eq $M1 ]]; then
        continue
      fi
      ffound=1
      for fldnm in lwdn_sfc precip q_ref slp swdn_sfc t_ref u_ref v_ref; do
        if [ -s $drnm/${prfx}*${yr}${MM}01-*${fldnm}.nc ]; then
          report_result $yr $MM $ens $fldnm 'ok'
        else
          report_result $yr $MM $ens $fldnm '!!! MISSING !!!'
        fi
      done
    done
  done
done
  
if [[ $ffound -eq 0 ]]; then
  report_result $yr $M1 $ens1 "all atmospheric fields" '!!! MISSING !!!'
fi

echo "------------------------------------------------------"
echo " " 

echo "Open Boundary Fields:  "
prfx='OBCs_spear_daily_init'
cd ${obc_dir}
pwd
ffound=0
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do 
  for ens in 01 02 03 04 05 06 07 08 09 10; do
    if [[ $ens1 -gt 0 ]] && [[ ! 10#$ens -eq 10#$ens1 ]]; then
      continue
    fi
    for drnm in $( ls -d ${yr}_e${ens} ); do
      if [ ! -d $drnm ]; then
        echo "$drnm does not exist, no data"
        continue
      fi
      for MM in 01 04 07 10; do
        if [[ $M1 -gt 0 ]] && [[ ! $MM -eq $M1 ]]; then
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

if [[ $ffound -eq 0 ]]; then
  report_result $yr $M1 $ens1 $prfx '!!! MISSING !!!'
fi

echo "------------------------------------------------------"
echo " " 

echo "River runoff daily fields:  "
prfx='glofas_runoff_NEP_816x342_daily_'
cd ${riv_dir}
pwd
for (( yr=$YR1; yr<=$YR2; yr+=1 )); do
  ifound=0
  for flriv in $( ls ${prfx}????-????.nc ); do
    dmm=$( echo $flriv | cut -d"." -f1 )
    rspan=$( echo $dmm | cut -d"_" -f6 )
    yrS=$( echo $rspan | cut -d"-" -f1 )
    yrE=$( echo $rspan | cut -d"-" -f2 )
    if [[ $yr -ge $yrS ]] && [[ $yr -lt $yrE ]]; then
      report_result $yr "1-12" "01-10" $prfx 'ok'
      ifound=1
      break
    fi
  done
  if [[ ifound -eq 0 ]]; then
    report_result $yr "1-12" "01-10" $prfx '!!! MISSING !!!'
  fi
done


echo "       "
echo " All Done "

exit 0 


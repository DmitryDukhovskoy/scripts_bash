#!/bin/bash
# 
# Use xml template to generate an XML for specific forecast
# seasonal forecasts with daily OB from SPEAR forecasts
#
# For ens run # 1 - save 5-day average fields for model analysis
# for other ens runs - standard output fields
#
# The script will create XML with SPEAR OBs using ens_spear for SPEAR ens. run #
# To run experiment 01 (with fixed SPEAR ens run): 
#   - generate XML with ens_spear = 01 (or whatever the fixed ens # is)
#   - run with expt_name using ens0 = 01, 02, ..., 10
#
# To run experiment 02 (with multi-ens SPEAR ens run): 
#   - generate XML with ens_run = ens0 actual ens run (01, 02, ..., 10)
#   - run with expt_name using esn0=01, 02, ..., 10 - same as  ens0
#
#
# For automated generation of xml and experiment run, use another script that calls this one: 
#  run_seasfcst_dailyOB.sh  YEAR_START [MOSTART] <---- !!! check expt=01 or 02 before running the script 
#
# Change expt_nmb to run with different OBC's options
# run_seasfcst_dailyOB.sh will call this script
#
# usage: ./create_seasfcst_dailyOB_xml.sh YRSTART MOSTART ENS0 ens_spear [expt_name] [5day_output - any number > 0]
# Day start: assumed day = 1 of the month
#
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DXML=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst_dailyOB
export XMLTMP=NEPphys_seasfcst_dailyOB_template.xml
export expt_name=NEPphys_frcst_dailyOB

if [[ $# -lt 4 ]]; then
  echo "ERROR start year months not specified"
  echo "usage: ./create_seasfcst_dailyOB_xml.sh YRSTART MOSTART ENS0 ens_spear [expt_name] [Nday_output flag]" 
  exit 1
fi

ystart=$1
MOS=$2
mstart=$(echo $MOS | awk '{printf("%02d", $1)}')
ens0=$3    #fixed SPEAR ens run used for OB fields, if 0 - will use seas. f/cast ens. run #
ens0=$( echo $ens0 | awk '{printf("%02d", $1)}')
ens_spear=$4
ens_spear=$( echo ${ens_spear} | awk '{printf("%02d", $1)}')
DOUTP=0    # Flag for N-daily average output

if [[ $# -eq 5 ]]; then
  expt_name=$5
elif [[ $# -eq 6 ]]; then
  expt_name=$5
  DOUTP=$6
fi

if [[ $# -gt 6 ]]; then
  echo "ERROR: more than 6 input parameters $#"
  exit 1
fi

echo " --- Preparing XML for ${expt_name}, OBs from SPEAR ens run=${ens_spear}  --- "

if [[ $DOUTP -eq 0 ]]; then
  sfx_end=""
  echo "Creating XML for ${ystart}-${mstart} standard output"
else 
  echo "Creating XML for ${ystart}-${mstart} 5-day avrg and standard output"
  sfx_end="-dayout"
fi

# Determine time span for atmospheric data, need last day of the last month in a 1 year fcst
/bin/cp $DAWK/dates.awk .

# Find year day to end the simulation, which is 365( or 366)-1 days forward in time
dnmb_now=$( echo "DATE2HYCOM" | awk -f dates.awk YR=$ystart MM=$mstart DD=1 )
dnmb_next=$( echo "DATE2HYCOM" | awk -f dates.awk YR=$(( ystart+1)) MM=$mstart DD=1 )
nadd=$(( dnmb_next-dnmb_now-1 ))
#echo "nadd=$nadd"

yrE=$( echo "ADD DAYS" | awk -f dates.awk yr1=$ystart mo1=$mstart d1=1 ndays=$nadd | \
       awk '{printf("%d",$1)}') 
moE=$( echo "ADD DAYS" | awk -f dates.awk yr1=$ystart mo1=$mstart d1=1 ndays=$nadd | \
       awk '{printf("%02d",$2)}')
dayE=$( echo "ADD DAYS" | awk -f dates.awk yr1=$ystart mo1=$mstart d1=1 ndays=$nadd | \
       awk '{printf("%02d",$3)}')


jdayS=$(echo "YRMO START DAY" | awk -f dates.awk y01=2004 MM=04 dd=1 | awk '{printf("%02d",$1)}')

atmosspan=${ystart}${mstart}01-${yrE}${moE}${dayE}

echo "atmosspan = ${atmosspan}"

# Determine time span for river data grouped in Nyears blocks
export DRIV=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_data/forecast_input_data/runoff
export flriver=XXX
rivspan=0
prfx='glofas_runoff_NEP_816x342_daily_'
cd $DRIV
for fls in $( ls ${prfx}????-????.nc ); do
  yrstr=$( echo $fls | cut -d"_" -f6 | cut -d"." -f1)
  yrS=$( echo $yrstr | cut -d"-" -f1 )
  yrE=$( echo $yrstr | cut -d"-" -f2 )
  if [[ $ystart -ge $yrS ]] && [[ $ystart -lt $yrE ]]; then
    flriver=$fls
    rivspan=$yrstr
    echo "f/cast init: $ystart, River file: $flriver, time span: $rivspan"
    break
  fi
done

if [[ $flriver == 'XXX' ]]; then
  echo "Could not find river input file and river time span for ${ystart}"
  exit 1
fi

cd $DOUT
pwd

# CHeck if template exists and has been updated but do not touch not to disrupt mutli-job submission
if [ ! -s $XMLTMP ]; then
  /bin/cp $DXML/$XMLTMP .
fi
nch=$( diff $XMLTMP $DXML/$XMLTMP | wc -l )
if [[ $nch -gt 0 ]]; then
  echo "$XMLTP has been changed, updating ..."
  /bin/rm -f $XMLTMP
  /bin/cp $DXML/$XMLTMP .
fi

bnm=$( echo $XMLTMP | cut -d "_" -f-3 )
#echo $bnm
#flout=${bnm}_${ystart}_${mstart}${sfx_end}_e{ens0}.xml
flout=${bnm}_${ystart}_${mstart}_e${ens0}.xml
#ens_spear=$( echo $ens0 | awk '{printf("%02d", $1)}')

export obc_file=OBCs_spear_daily_init${ystart}${mstart}01_e${ens_spear}.nc
export obc_subdir=${ystart}_e${ens_spear}
if [[ $DOUTP -eq 0 ]]; then
  export mom_diag=diag_table.MOM6_phys_standard
  export sis_diag=diag_table.SIS2_standard
else
  export mom_diag=diag_table.MOM6_phys_5day_standard
  export sis_diag=diag_table.SIS2_5day_standard
fi

/bin/rm -f $flout
sed -e 's|<property name="ystart" value=.*|<property name="ystart" value="'"${ystart}"'"/>|'\
    -e 's|<property name="mstart" value=.*|<property name="mstart" value="'"${mstart}"'"/>|'\
    -e 's|<property name="atmosspan" value=.*|<property name="atmosspan" value="'"${atmosspan}"'"/>|' \
    -e 's|<property name="obc_daily_file" value=.*|<property name="obc_daily_file" value="'"${obc_file}"'"/>|'\
    -e 's|<property name="obc_subdir" value=.*|<property name="obc_subdir" value="'"${obc_subdir}"'"/>|'\
    -e 's|<property name="rivspan" value=.*|<property name="rivspan" value="'"${rivspan}"'"/>|'\
    -e 's|<property name="expt_nm1" value=.*|<property name="expt_nm1" value="'"${expt_name}"'"/>|'\
    -e 's|<property name="mom6_diag" value=.*|<property name="mom6_diag" value="'"${mom_diag}"'"/>|'\
    -e 's|<property name="sis2_diag" value=.*|<property name="sis2_diag" value="'"${sis_diag}"'"/>|' $XMLTMP > $flout

chmod 750 $flout

#ls -l
#echo "Done "
#echo "Test run: ens=$ens"
echo "SPEAR OB from ens run=${ens_spear}"
echo "frerun -x $flout -p ncrc5.intel23 -q debug -r test -t repro NEPphys_frcst_dailyOB02_${ystart}-${mstart}-e${ens0} --overwrite"
echo "Seasonal fcast daily OB for ens=$ens0"
echo "frerun -x $flout -p ncrc5.intel23 -t repro NEPphys_frcst_dailyOB_${ystart}-${mstart}-e${ens0} --overwrite"

exit 0

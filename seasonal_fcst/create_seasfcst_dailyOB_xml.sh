#!/bin/bash
# 
# Use xml template to generate an XML for specific forecast
# seasonal forecasts with daily OB from SPEAR forecasts
#
# For ens 1 - save 5-day average fields for model analysis
# for other ens runs - standard output fields
#
# usage: ./create_seasfcst_dailyOB_xml.sh YRSTART MOSTART [5day_output - any number > 0]
# Day start: assumed day = 1 of the month
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DXML=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/gpfs/f5/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst_dailyOB
export XMLTMP=NEPphys_seasfcst_dailyOB_template.xml

if [[ $# -lt 2 ]]; then
  echo "ERROR start year months not specified"
  echo "usage: ./create_seasfcst_dailyOB_xml.sh YRSTART MOSTART [5day_output - any number > 0]" 
  exit 1
fi

DOUTP=0
if [[ $# -eq 3 ]]; then
  DOUTP=$3
fi

ystart=$1
MOS=$2
mstart=$(echo $MOS | awk '{printf("%02d", $1)}')
ens0=01

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
/bin/rm -f $XMLTMP
/bin/cp $DXML/$XMLTMP .

bnm=$( echo $XMLTMP | cut -d "_" -f-3 )
#echo $bnm
flout=${bnm}_${ystart}_${mstart}${sfx_end}.xml

export obc_file=OBCs_spear_daily_init${ystart}${mstart}01_e${ens0}.nc
export obc_subdir=${ystart}_e${ens0}
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
    -e 's|<property name="mom6_diag" value=.*|<property name="mom6_diag" value="'"${mom_diag}"'"/>|'\
    -e 's|<property name="sis2_diag" value=.*|<property name="sis2_diag" value="'"${sis_diag}"'"/>|' $XMLTMP > $flout

chmod 750 $flout

#ls -l
#echo "Done "

#echo "Test run: ens=$ens"
echo "frerun -x $flout -p ncrc5.intel23 -q debug -r test -t repro NEPphys_frcst_dailyOB_${ystart}-${mstart}-e${ens0} --overwrite"
echo "Seasonal fcast daily OB for ens=$ens0"
echo "frerun -x $flout -p ncrc5.intel23 -t repro NEPphys_frcst_dailyOB_${ystart}-${mstart}-e${ens0} --overwrite"

exit 0

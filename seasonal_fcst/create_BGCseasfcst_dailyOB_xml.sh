#!/bin/bash
# 
# Use xml template to generate an XML for specific BGC 
# seasonal forecasts with daily OB from SPEAR forecasts
#
# The script will create XML with SPEAR OBs using ens_spear for SPEAR ens. run #
#   - generate XML with ens_run = ens0 actual ens run (01, 02, ..., 10)
#   - run with expt_name using esn0=01, 02, ..., 10 - same as  ens0
#
#
# For automated generation of xml and experiment run, use another script that calls this one: 
# run_BGCseasfcst_dailyOB.sh --ys 1995 ...
#
#
set -u 

export DAWK=/ncrc/home1/Dmitry.Dukhovskoy/scripts/awk_utils
export DXML=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/NEP_xml
export DOUT=/gpfs/f6/cefi/scratch/Dmitry.Dukhovskoy/NEP_xml/xml_seasfcst_dailyOB
export DOUT=${DXML}/xml_bgc
export PLTF=ncrc6.intel23-repro
export XMLTMP=NEPbgc_seasfcstIrlx_dailyOB_tmplt.xml
export expt_name=NEPbgc_fcst_dailyOB

irlx_rate=24     # only used if irlx>0, rlx time scale
ens_spear=0      # SPEAR ensemble - assumed to be the same as the BGC run
ens0=0
mstart=0
ystart=0
flxml=""

# Function to print usage message
usage() {
  echo "Usage: $0 --ys 1994 --ms 10 --ens 3 --enspr 3 [--expt_name NEPbgc_frcst_dailyOB] [--xmltmp NEPbgc_tmpt.xml [--dayout 1] [irlx 24]"
  echo "  --ys          year to start the f/cast: 1993, ..." 
  echo "  --ms          month to start the f/cast, 1,4,7,10" 
  echo "  --ens         ensemble # to run: 1,..., 10"
  echo "  --expt_name   experiment name, optional, default=${expt_name}"
  echo "  --xmltmp      XML template filename to use, default=${XMLTMP}"
  echo "  --ilrx        max relax. hours, >0 - relxation applied,  default=${irlx}"
  echo "  --flxml       XML directive script used for generating this f/cast, optional"
  exit 1
}

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --ys)
      ystart=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --ms)
      mstart="$2"
      shift 2 
      ;;
    --ens)
      ens0="$2"
      shift 2
      ;;
    --expt_name)
      expt_name="$2"
      shift 2
      ;;
    --flxml)
      flxml="$2"
      shift 2
      ;;
    --xmltmp)
      XMLTMP="$2"
      shift 2
      ;;
    --irlx)
      irlx="$2"
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

ens_spear=$ens0

if (( $ystart < 1993 || $mstart == 0 || $ens_spear == 0 || $ens0 == 0 )); then
  echo "ERROR missing required fields: start year months ens_nmb "
  usage
fi

mstart=$(echo $mstart | awk '{printf("%02d", $1)}')
ens0=$( echo $ens0 | awk '{printf("%02d", $1)}')
ens_spear=$( echo ${ens_spear} | awk '{printf("%02d", $1)}')

if [[ $irlx -gt 0 ]]; then
  echo " --- Preparing XML for ${expt_name}, dailyOBs SPEAR ens run=${ens_spear}  ice rlx ${irlx}hrs --- "
else
  echo " --- The script create_BGCseasfcst_dailyOB_xml.sh has to be updated to handle no ice relaxation option ---"
  echo " --- Need to add logic to select SIS_override with the ice rlx option turned off, quitting ... ---"
  exit 5
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
ynext=$(( ystart+1 ))

echo "atmosspan = ${atmosspan}"

# ice relax. files:
irlx_rate=$(printf "%03d" "$irlx")
irlx_rate_file=relax_rate_${irlx_rate}hrs_v3.nc
irlx_fld_file=PIOMASv21_ithkn_iconc_${ystart}_${ynext}_avrg5yr.nc

cd $DOUT
pwd

# CHeck if template exists and has been updated 
if [ ! -s $XMLTMP ]; then
  /bin/cp $DXML/$XMLTMP .
fi
nch=$( diff $XMLTMP $DXML/$XMLTMP | wc -l )
if [[ $nch -gt 0 ]]; then
  echo "$XMLTMP has been changed, updating ..."
  /bin/rm -f $XMLTMP
  /bin/cp $DXML/$XMLTMP .
fi

bnm=$(echo "$XMLTMP" | cut -d "_" -f-3)
if [[ -z "$flxml" ]]; then
  flout="${bnm}_${ystart}_${mstart}_e${ens0}.xml"
else
  flout="$flxml"
fi

mom_diag="diag_table.MOM6_phys_75z_monthly"
sis_diag="diag_table.SIS2_standard_daily"
obc_file=OBCs_spear_daily_init${ystart}${mstart}01_e${ens_spear}.nc
obc_subdir=${ystart}_e${ens_spear}

if [[ ! -f "$XMLTMP" ]]; then
  echo "Error: XML template file $XMLTMP not found ..."
  exit 1
fi

/bin/rm -f $flout
sed -e 's|<property name="ystart" value=.*|<property name="ystart" value="'"${ystart}"'"/>|'\
    -e 's|<property name="mstart" value=.*|<property name="mstart" value="'"${mstart}"'"/>|'\
    -e 's|<property name="atmosspan" value=.*|<property name="atmosspan" value="'"${atmosspan}"'"/>|' \
    -e 's|<property name="obc_daily_file" value=.*|<property name="obc_daily_file" value="'"${obc_file}"'"/>|'\
    -e 's|<property name="obc_subdir" value=.*|<property name="obc_subdir" value="'"${obc_subdir}"'"/>|'\
    -e 's|<property name="irlx_rate_file" value=.*|<property name="irlx_rate_file" value="'"${irlx_rate_file}"'"/>|'\
    -e 's|<property name="irlx_fld_file" value=.*|<property name="irlx_fld_file" value="'"${irlx_fld_file}"'"/>|'\
    -e 's|<property name="expt_nm1" value=.*|<property name="expt_nm1" value="'"${expt_name}"'"/>|'\
    -e 's|<property name="mom6_diag" value=.*|<property name="mom6_diag" value="'"${mom_diag}"'"/>|'\
    -e 's|<property name="sis2_diag" value=.*|<property name="sis2_diag" value="'"${sis_diag}"'"/>|' $XMLTMP > $flout

chmod 750 $flout

#ls -l
#echo "Done "
#echo "Test run: ens=$ens"
echo "SPEAR OB from ens run=${ens_spear}"
echo "frerun -x $flout -p ncrc6.intel23 -q debug -r test -t repro ${expt_name}_${ystart}-${mstart}-e${ens0} --overwrite"
echo "Seasonal fcast daily OB for ens=$ens0"
echo "frerun -x $flout -p ncrc6.intel23 -t repro ${expt_name}_${ystart}-${mstart}-e${ens0} --overwrite"

exit 0

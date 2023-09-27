#!/bin/bash --login
#
# Main script to run diagnostics of the paraXXX experiment
# Name of experiment is in expt_name.txt 
# Need to update 
#
# Dmitry Dukhovskoy, NOAA/NWS/NCEP/EMC
#
set -x
set -u

touch expt_name.txt
if [! -s expt_name.txt ]; then
  echo "Need to provide experiment name in expt_name.txt"
  exit 1
fi

module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
module purge
module load intel/2022.1.2 impi/2022.1.2 contrib ncl/6.6.2 netcdf/4.6.1 hdf5 cdo/1.9.10 nccmp/1.9.0.1 nco/4.9.3 cairo/1.14.2 hpss/hpss
module list

export expt=`cat expt_name.txt`
export sfx="n-24"
export DHPSS=/NCEPDEV/emc-ocean/5year/Dan.Iredell/wcoss2.${expt}
export WD="/scratch1/NCEPDEV/stmp2/${USER}/rtofs_${expt}/run_diagn"
export DTRSF=/home/Dmitry.Dukhovskoy/scripts/transfer2rzdm
export lst=last_saved_${sfx}.txt
export hplst=hpss_output.txt
export hpdates=hpss_dates.txt
export DUTIL=/home/Dmitry.Dukhovskoy/scripts/awk_utils
export DPTHN=/home/Dmitry.Dukhovskoy/python/RTOFS_WWW
export DSCR=/home/Dmitry.Dukhovskoy/scripts/rtofs_diagnostics
#export DSCR=/home/Dmitry.Dukhovskoy/scripts/rtofs
#export DSCR2=/home/Dmitry.Dukhovskoy/scripts/transfer2rzdm


mkdir -pv ${WD}

cd $WD
pwd
ls -rlt

mkdir -pv ${WD}/logs 
/bin/rm -f *.out
/bin/mv -f *.log logs/. 

/bin/cp $DUTIL/dates.awk .

touch ${lst}
/bin/rm -f $hplst
touch $hplst
# Update list of HPSS saved output:
hsi -P ls -1 $DHPSS | grep rtofs\. > $hplst
#if [ $? -ne 0 ]; then
if [ ! -s $hplst ]; then
  echo " $hplst is empty "
  echo "Failure to connect to HPSS or path error ?"
  exit 1
fi

# Strip off the date
/bin/rm -f $hpdates
touch dmm.txt

nhpss=`grep -n 'rtofs\.' ${hplst} | tail -1 | awk '{split($0,aa,":"); print aa[1]}'`
echo "Found $nhpss output records on HPSS"
# Save HPSS dates, sorted from earliers to latest
for (( iline=1; iline<=$nhpss; iline++ ))
do
  str=`cat ${hplst} | head -${iline} | tail -1`
#  flname=`echo $str | awk -F/ '{print $NF-1}'`
  flname=`basename $str`
  echo $flname | cut -d'.' -f2 >> dmm.txt
done 
sort -n dmm.txt > $hpdates
/bin/rm dmm.txt

hpss_last=`tail -1 ${hpdates}`
#
# First check if the latest output has been saved:
# if list is absent - take the first saved rtofs on HPSS
# Sort list to find the first date
# Add + 1 to find the next date str
nprcs=`cat "$lst" | wc -l`
if [[ $nprcs == 0 ]]; then
#  rday_last=`hsi -P ls -l $DHPSS | grep rtofs\. | head -1 | awk '{print $9}' | cut -d'.' -f2`
  rday_last=0
else
  rday_last=`tail -1 ${lst}`
fi

echo " Last HPSS output $hpss_last"
echo " Last analyzed $rday_last" 
# Check if HPSS has new output:
if (( $hpss_last == $rday_last )); then
  echo "  No new $expt output saved on HPSS, quiting "
  exit 0
fi

# Find missing dates to process:
export fmssd=hpss_missed.txt
/bin/rm -f $fmssd
touch $fmssd

if [[ $nprcs == 0 ]]; then
  rdayS=`head -1 $hpdates`
  /bin/cp ${hpdates} ${fmssd}
else
  nLn=`grep -n $rday_last $hpdates | awk '{split($0,aa,":"); print aa[1]}'`
  nLn=$(( nLn + 1 ))
  
  for (( iline=$nLn; iline<=$nhpss; iline++ ))
  do
    cat ${hpdates} | head -${iline} | tail -1 >> $fmssd
  done
fi

cd $WD
pwd
ls -rlt

# ====================================
# 
#  Processing HPSS output
#
# ====================================
echo "Start Processing HPSS output"
# clean old python scripts:
mkdir -pv bkp
/bin/rm -f pyjob*.sh
/bin/rm -f plot_*0??.py
/bin/rm -f find_*0??.py
/bin/rm -f gulf*_*0??.py
/bin/mv -f *.py bkp/.
/bin/rm -r -f  __pycache__

for flnm in gulfstream_wall.py mod_gulfstream.py mod_time.py mod_utils.py \
            find_collapsed_lrs.py plot_archv_xsct_layres.py plot_sect.py \
            plot_xsct_TS.py find_collapsed_lrs.py plot_rtofs2z_TSmap.py
do
  /bin/cp $DPTHN/$flnm .
done

ls -l *.py
echo " "

/bin/cp $DSCR/sub_pyjob.sh .

export getrtofs=get_rtofs_archv.sh
/bin/cp $DSCR/${getrtofs} .
sed -i "s|export expt=.*|export expt=${expt}|" $getrtofs
sed -i "s|export D=.*|export D=${WD}|" $getrtofs
chmod 700 $getrtofs

#export DFIG=$WD/fig
export IDM=4500
export JDM=3298

#mkdir -pv $DFIG

# Save list of processed files:
dnow=`date +%Y%m%d`
fbkp="$lst-$dnow"
/bin/cp $lst $WD/logs/$fbkp

# Process each missing day 
ijb=0
for rdate in $(cat $fmssd)
do
  export DOUT=$WD/rtofs.${rdate}
  export DFIG=$DOUT/fig
  mkdir -pv $DOUT
  mkdir -pv $DFIG

#
# Get data if needed:
  echo " "
  echo "-------- "
  if [ -s $DOUT/rtofs_glo.t00z.${sfx}.archv.a ] && \
     [ -s $DOUT/rtofs_glo.t00z.${sfx}.archv.a ]; then
    echo " HPSS output files exist "
  else
    echo "Fetching data for ${rdate} ${sfx} ..."
    ./${getrtofs} ${rdate} ${sfx}
    wait
  fi

  cd $WD
#
# Plot vertical layers:
  fpthn=plot_archv_xsct_layres.py
  fhcm="rtofs_glo.t00z.${sfx}.archv"

# 0=GoM1, 1=Portg, 2=NAtl1, ..., 12=IndO1
  list_sct=[0,1,2,3,4,5,6,7,8,9,10,11,12,13]  # list of sections to plot
  ijb=$(( ijb + 1))
  if (( ijb > 50 )); then
    printf "Too many jobs ${ijb}, exiting ... "
    break
#    exit 1
  fi
  jnmb=`echo ${ijb} | awk '{printf("%03d",$1)}'`
# 
# Plot layers 
#    fpyrun=`echo $fpthn | awk -F. '{print $(NF-1)}'`
  fpyrun="plot_layrs${jnmb}.py"
  /bin/rm -f $fpyrun 
 
  sed -e "s|^rdate0[ ]*=.*|rdate0 = '${rdate}'|"\
      -e "s|^expt[ ]*=.*|expt  = '${expt}'|"\
      -e "s|^sfx[ ]*=.*|sfx    = '${sfx}'|"\
      -e "s|^isct[ ]*=.*|isct   = ${list_sct}|"\
      -e "s|^f_figsave[ ]=.*|f_figsave = True|"\
      -e "s|^f_intract[ ]*=.*|f_intract = False|"\
      -e "s|^IDM[ ]*=.*|IDM  = ${IDM}|"\
      -e "s|^JDM[ ]*=.*|JDM  = ${JDM}|"\
      -e "s|^pthfig[ ]*=.*|pthfig = '${DFIG}/'|"\
      -e "s|^pthhcm[ ]*=.*|pthhcm = '${DOUT}/'|" \
      -e "s|^fhcm[ ]*=.*|fhcm   = '${fhcm}'|" $fpthn > $fpyrun

# Submitting run sbatch script
# sbatch -q batch -t 8:00:00 --nodes=1 -A marine-cpu batch.job
  sed -e "s|^pexe=.*|pexe=${fpyrun}|" \
      -e "s|export WD=.*|export WD=${WD}|" sub_pyjob.sh > pyjob${jnmb}.sh

  flog=plot_layrs${jnmb}.log
#  sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh
# Capture the job id:
  job1id=$(sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh | cut -d " " -f4)
  echo "Submitted job $job1id"

# Plot T/S sections:
  for fldp in temp salin
  do
    cd $WD
    ftspy=plot_xsct_TS.py
    ftsrun="plot_xsct_${fldp}${jnmb}.py"
    /bin/rm -f $ftsrun

    sed -e "s|^rdate0[ ]*=.*|rdate0 = '${rdate}'|"\
        -e "s|^expt[ ]*=.*|expt  = '${expt}'|"\
        -e "s|^sfx[ ]*=.*|sfx    = '${sfx}'|"\
        -e "s|^isct[ ]*=.*|isct   = ${list_sct}|"\
        -e "s|^f_figsave[ ]=.*|f_figsave = True|"\
        -e "s|^f_intract[ ]*=.*|f_intract = False|"\
        -e "s|^IDM[ ]*=.*|IDM  = ${IDM}|"\
        -e "s|^JDM[ ]*=.*|JDM  = ${JDM}|"\
        -e "s|^fld[ ]*=.*|fld    = '${fldp}'|"\
        -e "s|^pthfig[ ]*=.*|pthfig = '${DFIG}/'|"\
        -e "s|^pthhcm[ ]*=.*|pthhcm = '${DOUT}/'|" \
        -e "s|^fhcm[ ]*=.*|fhcm   = '${fhcm}'|" $ftspy > $ftsrun

# Submitting run sbatch script
# sbatch -q batch -t 8:00:00 --nodes=1 -A marine-cpu batch.job
    subpy=pyjob_${fldp}${jnmb}.sh
    sed -e "s|^pexe=.*|pexe=${ftsrun}|" \
        -e "s|export WD=.*|export WD=${WD}|" sub_pyjob.sh > $subpy

    flog=plot_${fldp}${jnmb}.log
#  sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh
# Capture the job id:
    job2id=$(sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu ${subpy} | cut -d " " -f4)
    echo "Submitted job $job2id"

  done
 
# jid=$(sbatch --dependency=afterok:${jid} job${k}.slurm | cut -d ' ' -f4) 

# Plot think thick figures
  cd $WD
  ftspy=find_collapsed_lrs.py
  ftsrun="find_collapsed${jnmb}.py"
  /bin/rm -f $ftsrun

  sed -e "s|^rdate0[ ]*=.*|rdate0 = '${rdate}'|"\
      -e "s|^expt[ ]*=.*|expt  = '${expt}'|"\
      -e "s|^sfx[ ]*=.*|sfx    = '${sfx}'|"\
      -e "s|^f_figsave[ ]=.*|f_figsave = True|"\
      -e "s|^f_intract[ ]*=.*|f_intract = False|"\
      -e "s|^pthfig[ ]*=.*|pthfig = '${DFIG}/'|"\
      -e "s|^pthhcm[ ]*=.*|pthhcm = '${DOUT}/'|" \
      -e "s|^fhcm[ ]*=.*|fhcm   = '${fhcm}'|" $ftspy > $ftsrun

# Submitting run sbatch script
# sbatch -q batch -t 8:00:00 --nodes=1 -A marine-cpu batch.job
  subpy=pyjob_collapsedLrs${jnmb}.sh
  sed -e "s|^pexe=.*|pexe=${ftsrun}|" \
      -e "s|export WD=.*|export WD=${WD}|" sub_pyjob.sh > $subpy

  flog=find_collapsed${jnmb}.log
#  sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh
# Capture the job id:
  job3id=$(sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu ${subpy} | cut -d " " -f4)
  echo "Submitted job $job3id"

# Gulf Stream front figures
  cd $WD
  ftspy="gulfstream_wall.py"
  ftsrun="gulfstream_wall${jnmb}.py"
  /bin/rm -f $ftsrun

  sed -e "s|^rdate0[ ]*=.*|rdate0 = '${rdate}'|"\
      -e "s|^expt[ ]*=.*|expt  = '${expt}'|"\
      -e "s|^sfx[ ]*=.*|sfx    = '${sfx}'|"\
      -e "s|^f_figsave[ ]=.*|f_figsave = True|"\
      -e "s|^f_intract[ ]*=.*|f_intract = False|"\
      -e "s|^pthfig[ ]*=.*|pthfig = '${DFIG}/'|"\
      -e "s|^pthhcm[ ]*=.*|pthhcm = '${DOUT}/'|" \
      -e "s|^fhcm[ ]*=.*|fhcm   = '${fhcm}'|" $ftspy > $ftsrun

# Submitting run sbatch script
  subpy=pyjob_glfstrFront${jnmb}.sh
  sed -e "s|^pexe=.*|pexe=${ftsrun}|" \
      -e "s|export WD=.*|export WD=${WD}|" sub_pyjob.sh > $subpy

  flog=glfstr_front${jnmb}.log
#  sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh
# Capture the job id:
  job4id=$(sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu ${subpy} | cut -d " " -f4)
  echo "Submitted job $job4id"

#
# 2D maps of T and S
  list_maps=[0,1,2]
  zplt="-150."
  for fldp in temp salin
  do
    cd $WD
    ftspy="plot_rtofs2z_TSmap.py"
    ftsrun="plot_TSmap_${fldp}${jnmb}.py"
    /bin/rm -f $ftsrun

    sed -e "s|^rdate0[ ]*=.*|rdate0 = '${rdate}'|"\
        -e "s|^expt[ ]*=.*|expt  = '${expt}'|"\
        -e "s|^sfx[ ]*=.*|sfx    = '${sfx}'|"\
        -e "s|^isct[ ]*=.*|isct   = ${list_maps}|"\
        -e "s|^z0[ ]*=.*|z0  = ${zplt}|"\
        -e "s|^f_figsave[ ]=.*|f_figsave = True|"\
        -e "s|^f_intract[ ]*=.*|f_intract = False|"\
        -e "s|^fld[ ]*=.*|fld    = '${fldp}'|"\
        -e "s|^pthfig[ ]*=.*|pthfig = '${DFIG}/'|"\
        -e "s|^pthhcm[ ]*=.*|pthhcm = '${DOUT}/'|" \
        -e "s|^fhcm[ ]*=.*|fhcm   = '${fhcm}'|" $ftspy > $ftsrun

# Submitting run sbatch script
# sbatch -q batch -t 8:00:00 --nodes=1 -A marine-cpu batch.job
    subpy=pyjob_map${fldp}${jnmb}.sh
    sed -e "s|^pexe=.*|pexe=${ftsrun}|" \
        -e "s|export WD=.*|export WD=${WD}|" sub_pyjob.sh > $subpy

    flog=plot_map${fldp}${jnmb}.log
#  sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu pyjob${jnmb}.sh
# Capture the job id:
    job5id=$(sbatch -q batch -t 1:00:00 --nodes=1 -A marine-cpu ${subpy} | cut -d " " -f4)
    echo "Submitted job $job5id"

  done

# ============= !!!!!
# exit 5
# Close the loop, add dependencies to the python slurm jobs
# do the rest in a separate script that will be run by crone
# 
# ============ !!!!!
done   # missing dates loop

cd $DTRSF
pwd
ls -l

export ftr=transfer2www.sh
export ftr2=transfer2wwwR.sh
sed -e "s|^export[ ]*expt=.*|export expt=${expt}|" \
    -e "s|^export[ ]*sfx=.*|export sfx=${sfx}|"\
    -e "s|^export[ ]*lst=.*|export lst=${lst}|"\
    -e "s|^export[ ]*fmssd=.*|export fmssd=${fmssd}|"\
    -e "s|^export[ ]*WD=.*|export WD=${WD}|" $ftr > $ftr2

chmod 750 $ftr2

echo "   ======== All Done ========="
exit 0 

# use crone
# Next - call transfer script

# Modify shell script for rzdm
# copy from script dir new_web_dir.sh
#cd $WD
#cp ${DSCR2}/*.sh .
# Change rdate in shell and other vavr in index.php 
# 

# Copy saved figures & updated script, *.php to rzdm
#
#
#
# Update last_saved_n-24.txt $lst if success
#  fdone=1
#  if [[ $fdone == 0 ]]; then
#    echo $rdate >> $lst
#  fi
  

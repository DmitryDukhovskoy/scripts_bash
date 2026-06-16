#!/bin/bash
#
# link restart files to current run directory
# for SFS run
#
set -u

run_name=ufs_SFS

usage() {
  echo "Usage: $0 --yr YYYY --mm MM --dd DD [--hr HH]"
  echo " --yr     restart year" 
  echo " --mm     restart month"
  echo " --dd     restart day"
  echo " --hr     restart hour, default=0"
  echo " --rdir   run directory, (default) 0: rdir=current dir (/INPUT will be stripped off), =1 - use DRUN"
  exit 1
}


HR=0
YR=0
MM=0
DD=0
rdir=0
DREST=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS/restart_sfs_C192mx025
#DRUN=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS/sfs_test2_c192mx025
DRUN0=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS/sfs_C192mx025_run2

# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --yr)
      YR=$2
      shift 2 
      ;;
    --mm)
      MM=$2
      shift 2
      ;;
    --dd)
      DD=$2
      shift 2
      ;;
    --hr)
      HR=$2
      shift 2
      ;;
    --rdir)
      rdir=$2
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

if [[ $YR -eq 0 ]]; then
  echo "ERR: year not defined"
  usage
fi

if [[ $MM -eq 0 ]]; then
  echo "ERR: MM not defined"
  usage
fi

if [[ $DD -eq 0 ]]; then
  echo "ERR: DD not defined"
  usage
fi

if [[ $rdir != 0 && $rdir != 1 ]]; then
  echo "ERR: rdir should be 0 or 1"
  usage
fi

syst=$(hostname)
if [[ ${syst:0:4} != "gaea" ]]; then
  echo "ERR: Update directories for ${syst}, default=gaea"
  exit 1
fi

if [[ $rdir == 0 ]]; then
  CDIR=$(pwd)

  # If already inside INPUT, remove trailing /INPUT
  if [[ "${CDIR##*/}" == "INPUT" ]]; then
    DRUN="${CDIR%/INPUT}"
  else
    DRUN="$CDIR"
  fi

else
  DRUN="$DRUN0"
fi

echo "creating restart links for: $YR/$MM/$DD $HR"
echo "RUN DIR: $DRUN"

if [[ ! -d "$DRUN/INPUT" ]]; then
  echo "ERR: $DRUN/INPUT does not exist"
  exit 1
fi

echo "RUN DIR $DRUN"
cd "$DRUN/INPUT" || exit 1
pwd

#--------------------------------------------------------
# Fcuntion: create symlink and verify target is non-empty
#--------------------------------------------------------
link_and_check () {
  local src=$1
  local dst=$2

  if [[ ! -f "$src" ]]; then
    echo "ERR: missing source file $src"
    exit 1
  fi

  rm -f "$dst"

  echo "linking: $dst -> $src"
  ln -sf "$src" "$dst"

  # Verify link resolves to a non-empty file
  if [[ ! -s "$dst" ]]; then
    echo "ERR: bad symlink or empty file: $dst -> $src"
    exit 1
  fi
}


nsec=$(( HR*3600 ))
dstamp=$(printf "%04d%02d%02d" "$YR" "$MM" "$DD")
hstamp=$(printf "%02d" "$HR")
sstamp=$(printf "%06d" "$nsec")

# Atmosphere restarts:
DATM="${DREST}/atmos/${dstamp}.${hstamp}"

for i in 1 2 3 4 5 6; do
  for sfx in sfc_data gfs_data; do
    fl="${sfx}.tile${i}.nc"
    src="${DATM}/${fl}"

    link_and_check "$src" "$fl"

  done
done

# Control file
fl="gfs_ctrl.nc"
src="${DATM}/${fl}"

link_and_check "$src" "$fl"

# Ice restart:
DICE="${DREST}/ice"
flice="${dstamp}.${hstamp}.cice_model.res.nc"
src="${DICE}/${flice}"

link_and_check "$src" "cice_model.res.nc"

# Ocean restart:
# Only 1 MOM restart is assumed, need to change if > 1 MOM.res_*.nc 
DOCN="${DREST}/ocean"
flocn="${dstamp}.${sstamp}.MOM.res.nc"
src="${DOCN}/${flocn}"

link_and_check "$src" "MOM.res.nc"


exit 0



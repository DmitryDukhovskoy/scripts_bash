#!/bin/bash
# 
# copy / soft link UFS SFS parameter / config files
# MOM_input and ice_in - default not, if yes - existing files will be overridden
#
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --expt NAME --param NAME [options]

Required:
  --param     Parameter set name (e.g. cice_test)

Optional:
  --expt      Experiment/run directory (default: current dir)
  --icemom    Handle ice_in and MOM_input (0=off, 1=on; default=0)
  --copy      Copy files (1) or symlink (0; default)

EOF
  exit 1
}


# Default values:
DRT=/gpfs/f6/sfs-emc/proj-shared/Dmitry.Dukhovskoy/RUNDIRS
expt="None"
param="None"
copy=0
icemom=0

FILES=(
  data_table
  diag_table
  field_table
  input.nml
  model_configure
  noahmptable.tbl
  ufs.configure
)

# copy link functions
link_or_copy() {
  local src="$1"
  local dest="$2"
  local fname
  fname="$(basename "$src")"

  if [[ ! -f "$src" ]]; then
    echo "WARNING: Missing file: $src"
    return
  fi

  rm -f "$dest/$fname"

  if [[ $copy -eq 1 ]]; then
    echo "cp $src --> $dest"
    cp "$src" "$dest/"
  else
    echo "ln -sf $src --> $dest"
    ln -sf "$src" "$dest/"
  fi
}

backup_if_exists() {
  local f="$1"
  if [[ -f "$f" ]]; then
    mv -f "$f" "${f}-bkp"
  fi
}


# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --expt)
      expt="$2"; shift 2 ;;
    --param)
      param="$2"; shift 2 ;;
    --icemom)
      icemom="$2"; shift 2 ;;
    --copy)
      copy="$2"; shift 2 ;;
    --help)
      usage ;;
    *)
      echo "ERROR: Unknown option $1"
      usage ;;
  esac
done


# ----------------------
# Validate input
# ----------------------
if [[ "$param" == "None" ]]; then
  echo "ERROR: --param is required"
  usage
fi

# Run directory
if [[ "$expt" == "None" ]]; then
  DRUN="$(pwd)"
else
  DRUN="${DRT}/${expt}"
fi

DPARAM="${DRT}/params_C192mc025_sfs/params_${param}"

# Check directories
if [[ ! -d "$DRUN" ]]; then
  echo "ERROR: Run directory not found: $DRUN"
  exit 1
fi

if [[ ! -d "$DPARAM" ]]; then
  echo "ERROR: Param directory not found: $DPARAM"
  exit 1
fi

echo "Working in: $DRUN"
cd "$DRUN"


# Main files
echo $([[ $copy -eq 1 ]] && echo "Copying files" || echo "Creating symlinks")

for fl in "${FILES[@]}"; do
  link_or_copy "$DPARAM/$fl" "$DRUN"
done

# CICE and MOM input files
if [[ $icemom -eq 1 ]]; then
  echo "copying/linking ice_in and MOM_input"

  # ice_in in run dir
  backup_if_exists "ice_in"
  link_or_copy "$DPARAM/ice_in" "$DRUN"

  # MOM_input in INPUT/
  (
    cd INPUT || { echo "ERROR: INPUT directory missing"; exit 1; }
    backup_if_exists "MOM_input"
    link_or_copy "$DPARAM/MOM_input" "$(pwd)"
  )
fi

echo "All done"
exit 0



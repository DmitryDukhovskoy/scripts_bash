#!/bin/bash
#
# Compile GFS global workflow 
# EMC global workflow:
# https://global-workflow.readthedocs.io/en/latest/
#
# To run SFS style:
# https://github.com/NeilBarton-NOAA/global-workflow/tree/sfs_ICS
# or SFSBeta0.1 Progress SFSbeta0.1 (To set up GW)
#
# ----------
# GFS:
# on C6 Gaea use:
# https://github.com/JessicaMeixner-NOAA/global-workflow/tree/retrotest14update

set -u 

# Try to load git-lfs if it's not available
if ! command -v git-lfs >/dev/null 2>&1; then
  echo "Trying to load git-lfs module..."
  module load git-lfs
fi

# Check if git-lfs is available
if command -v git-lfs >/dev/null 2>&1; then
  echo "Git LFS is available"

  # Check if Git LFS is initialized
  if ! git lfs env | grep -q "LocalWorkingDir"; then
      echo "Git LFS not initialized. Running: git lfs install"
      git lfs install
  else
      echo "Git LFS already initialized"
  fi
else
  echo "ERROR: Git LFS is not installed or not in PATH"
  exit 1  
fi

REPO=JessicaMeixner-NOAA
BRANCH=retrotest14update

SFS=F
GEFS=F
GFS=T
COMP=T  

usage() {
  echo "Usage: $0 --sfs T/F [--gefs T/F] [--gfs T/F] [--comp T/F]"
  echo "  --sfs T/F   clone and compile SFS, default F"
  echo "  --gfs T/F   clone and compile GFS, default T"
  echo "  --gefs T/F  clone and compile GEFS, default F"
  echo "  --comp T/F  F: clone only, T: clone and compile, default=T "
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --sfs) SFS=${2^^}; shift 2 ;;
    --gfs) GFS=${2^^}; shift 2 ;;
    --comp) COMP=${2^^}; shift 2 ;;
    --help) usage; exit 0 ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    shift 1
    ;;
  esac
done

# check out code
# DD_WORKDIR - see .bashrc
#code=gw_${BRANCH////\_}_${REPO}
code=gw_rt14update_JM
TOPDIR=${DD_WORKDIR}/CODE
mkdir -pv ${TOPDIR} 
cd "${TOPDIR}" || { echo "Failed to cd to ${TOPDIR}"; exit 1; }
pwd

# https://github.com/JessicaMeixner-NOAA/global-workflow.git
if [[ ! -d ${code} ]]; then
  echo "checking out https://github.com/${REPO}/global-workflow.git branch ${BRANCH} ---> ${code}"
    git clone --recursive -b ${BRANCH} https://github.com/${REPO}/global-workflow.git ${code}
else
  echo "${code} exist, skipping cloning ..."
fi

# Compile
# Note - it didn't work for OPTIONS=gfs
# Did  sorc/ ./build_all.sh gfs gdas  instead
if [[ "${COMP^^}" == T ]]; then
  OPTIONS=""
  [[ ${SFS} == T ]] && OPTIONS="${OPTIONS}sfs "
  [[ ${GEFS} == T ]] && OPTIONS="${OPTIONS}gefs "
  [[ ${GFS} == T ]] && OPTIONS="${OPTIONS}gfs "
  echo "COMPILE OPTIONS: ${OPTIONS}"
  cd ${TOPDIR}/${code}/sorc
  sh link_workflow.sh
  sh build_compute.sh -A ${COMPUTE_ACCOUNT} ${OPTIONS} >& ${TOPDIR}/compile_logs/build_${code}.log &
fi

exit 0


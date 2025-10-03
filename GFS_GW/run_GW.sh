#!/bin/bash
#
# Test configuration are defined by YAML:
# YAMLS of test configurations are at:
# https://github.com/NOAA-EMC/global-workflow/tree/develop/dev/ci/cases/pr
# 
#  dev/ci/cases/gfsv17/C384mx025_3DVarAOWCDA.yaml 
# dev/parm/config/gfs/config.marineanl.j2 
set -u

#REPO=NOAA-EMC && HASH=develop
#REPO=NeilBarton-NOAA && HASH=sfs_ICS
#REPO=XiaqiongZhou-NOAA && HASH=SFSbeta0.1
REPO=JM
HASH=rt14update
SFS_BASELINE=F
DEBUG=F

HOMEgfs=${1:-${DD_WORKDIR}/CODE/gw_${HASH////\_}_${REPO}}
#YAML=${2:-${HOMEgfs}/workflow/GEFS_16d.yaml}

# YAML test run:
YAML=${HOMEgfs}/dev/ci/cases/gfsv17/C384mx025_3DVarAOWCDA.yaml
# YAMLS for SFS
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C96mx100_S2S_CPC_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C96mx100_S2S_REPLAY_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2S_CPC_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2S_REPLAY_ICS.yaml
#YAML=${HOMEgfs}/dev/ci/cases/sfs/C192mx025_S2SW_REPLAY_ICS.yaml
# PR Testing
#YAML=${HOMEgfs}/dev/ci/cases/pr/C96mx100_S2S.yaml
#YAML=${HOMEgfs}/dev/ci/cases/pr/C48_S2SWA_gefs.yaml
#YAML=${HOMEgfs}/dev/ci/cases/pr/C48_S2SW.yaml
#YAML=${HOMEgfs}/dev/ci/cases/pr/C96_atm3DVar.yaml

export pslot=${HASH}_$(basename ${YAML/.yaml*})
echo "pslot=${pslot}"

# Check Code
echo "HOMEgfs=${HOMEgfs}"
echo "YAML=${YAML}"
[[ ! -d ${HOMEgfs} ]] && echo "code is not at ${HOMEgfs}" &&  exit 1
[[ ! -f ${YAML} ]] && echo "yaml file not at ${YAML}" &&  exit 1

# Machine Specific and Personallized options
export TOPICDIR=${DD_WORKDIR}/ICs
export RUNTESTS=${DD_WORKDIR}/RUNS
machine=$(uname -n)
[[ ${machine:0:3} == hfe ]] && m=hera && RUNDIRS=/scratch1/NCEPDEV/stmp2/${USER}/RUNDIRS
[[ ${machine} == *[cd]login* ]] && m=wcoss2
[[ ${machine} == *Orion* ]] && m=orion && RUNDIRS=/work/noaa/stmp/${USER}/ORION/RUNDIRS
[[ ${machine} == hercules* ]] && m=hercules && RUNDIRS=/work2/noaa/stmp/${USER}/HERCULES/RUNDIRS
[[ ${machine} == gaea* ]] && m=gaeac6 && RUNDIRS=/gpfs/f6/sfs-emc/world-shared/${USER}/RUNDIRS

# remove previous RUNDIR if it exists
if [[ -d ${RUNDIRS}/${pslot} ]]; then
    echo "Removing RUNDIR: ${RUNDIRS}/${pslot}"
    rm -rf ${RUNDIRS}/${pslot}
fi

# set up run
DSCR=$(dirname "$0")
# Do not need this? 
#source ${HOMEgfs}/dev/ci/platforms/config.${m/.*}
source ${HOMEgfs}/dev/ush/gw_setup.sh
export YAML_DIR=${HOMEgfs}
export HPC_ACCOUNT=${COMPUTE_ACCOUNT}
${HOMEgfs}/dev/workflow/create_experiment.py --yaml "${YAML}"
echo "FINISHED: create_experiment.py"

exit 5
# Below is SFS - need to see what is relevant
# !!!

# if yes, add all SFS dates
[[ ${SFS_BASELINE} == T ]] && ${PWD}/SFS-add_basline_dates.sh ${PWD}/${pslot}.xml

# Soft link items into EXPDIR for easier development
TOPEXPDIR=${RUNTESTS}/EXPDIR/${pslot}
set +u && source ${TOPEXPDIR}/config.base && set -u
cd ${TOPEXPDIR}

ln -sf ${HOMEgfs} GW-CODE
ln -sf ${HOMEgfs}/dev/workflow/setup_xml.py .
ln -sf ${HOMEgfs}/dev/workflow/rocoto_viewer.py .
ln -sf ${HOMEgfs}/dev/parm/config ORIG_CONFIGS
ln -sf ${COMROOT}/${PSLOT}/logs LOGS_COMROOT
ln -sf ${RUNDIRS}/${PSLOT} RUNDIRS
echo "FINISHED: soft-linking to EXPDIR"
if [[ ${DEBUG} == T ]]; then
    echo "DEBUGING, run set-up.xml in $EXPDIR" && exit 1
fi

# start rocotorun and add crontab
xml_file=${PWD}/${pslot}.xml && db_file=${PWD}/${pslot}.db && cron_file=${PWD}/${pslot}.crontab
~/TOOLS/bin/add-to-crontab ${cron_file}
rocotorun -d ${db_file} -w ${xml_file}
echo "CRONTAB INFO:"
echo "machine=${machine}"
echo "cron_file=${cron_file}"
echo "db=${db_file}"
echo "xml=${xml_file}"




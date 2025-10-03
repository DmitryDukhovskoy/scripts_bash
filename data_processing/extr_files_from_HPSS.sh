#!/bin/bash
#
# Note have to be on dtn node for accessing HPSS from gaea !
# Use interactive job first to get on dtn
#
# Extract atmospheric surface files from tar on HPSS
#
set -ue

expt=rt13_upd01_stream3
init=2025010400
flsfx=gfs.t00z.sfcf
hrS=0
hrE=240
dhr=3

usage() {
  echo "Usage: $0 --expt <rt13_upd01_stream3> --init <2025010400> "
  echo "  --expt    Experiment name should match dir name on HPSS"
  echo "  --init    initialization date YYYYMMDDhh"
  exit 1
}


# input with key arguments:
# Parse the command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --expt)
      expt=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --init)
      init=$2
      shift 2
      ;;
    *)
    echo "Error: Unrecognized option $1"
    usage
    ;;
  esac
done

init_day=${init:: -2}
pth_hpss="/NCEPDEV/emc-global/2year/emc.glopara/WCOSS2/GFSv17/${expt}/${init}"
gfs_tar=gfs_netcdfb.tar
pthsfx="gfs.${init_day}/00/model/atmos/history"
pth_arch="/gpfs/f6/sfs-cpu/scratch/Dmitry.Dukhovskoy/gfs_output/${expt}/atmos_${init}"
echo "Extracting ${flsfx} from HPSS: ${pth_hpss}"

mkdir -pv "${pth_arch}"

cd "${pth_arch}" || { echo "Cannot cd to ${pth_arch}"; exit 1; }
pwd

for (( fhr=$hrS; fhr<=$hrE; fhr+=dhr )); do
  fhr0=$(printf "%03d" "$fhr")
  gfs_file="${flsfx}${fhr0}.nc"
  echo "extracting ${gfs_file}"

  htar -xvf "${pth_hpss}/${gfs_tar}" "${pthsfx}/${gfs_file}"
  if [ $? -ne 0 ]; then
    echo "Failed"
    exit 2
  fi

done

# remove unneeded directories:
cd "${pth_arch}" || { echo "2. Cannot cd to ${pth_arch}"; exit 1; }
mv ${pthsfx}/*.nc .
rmdir -pv ${pthsfx}
 
echo " All Done "

exit 0 


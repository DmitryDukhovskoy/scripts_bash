#!/bin/bash
#
# The script submits jobs to perform hindcast simulations
# 1-year long
# Next run is submitted after the previous has been successfully finished
# YRS = Start with a run that has all INPUT fields ready to initiate the runs
# Then if YRS is finished (successfully)
# The script will send the output to PPAN and sets the links for the next run
# for YRS+1 - YRE
#
set -u

YRS=0
YRE=0


usage() {
  echo "Usage: $0 --yrs 1994 --yre 2015 "
  echo "  --yrs start year of the runs"
  echo "  --yre end year"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --yrs)
      YRS=$2
      shift 2 # Move past the flag and its arg. to the next flag
      ;;
    --yre)
      YRE=$2
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

if [[ $YRS -eq 0 ]] || [[ $YRE -eq 0 ]]; then
  echo 'ERR: missing YRS or YRE'
  usage
fi

DRUN=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/work/NEP_irlx_test
DSCR=/ncrc/home1/Dmitry.Dukhovskoy/scripts/seasonal_fcst
cd $DRUN || { echo "Failed to cd to $DRUN"; exit 1; }
pwd

# Submit the first job
job_id=$(sbatch sub_mom6sis.sh | awk '{print $4}')
if [[ -z "$job_id" ]]; then
  echo "ERROR: Failed to submit initial job"
  exit 1
fi
echo "Submitted initial job: sub_mom6sis.sh with Job ID: $job_id"

# Loop through years
for (( yr=$YRS+1; yr<=$YRE; yr++ )); do
  # Create wrapper script for year
  wrapper_script="run_and_prep_${yr}.sh"
  cat > "$wrapper_script" <<EOF
#!/bin/bash
#SBATCH --job-name=SISirlx_${yr}
#SBATCH --error=err_${yr}.log
#SBATCH --account=ira-cefi
#SBATCH --qos=normal
#SBATCH --partition=batch
#SBATCH --clusters=c6
#SBATCH --nodes=16
#SBATCH --time=4:00:00
#SBATCH --output=%x.o%j
#SBATCH --export=NONE

set -e  # To avoid spawning jobs, fail the job on any error
set -ux

set +x
source $MODULESHOME/init/bash
##source /opt/cray/pe/lmod/lmod/init/bash
##module unload darshan-runtime
module unload cray-libsci
module unload cray-netcdf cray-hdf5 fre
module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu PrgEnv-cray
module load PrgEnv-intel/8.6.0
module unload intel intel-classic intel-oneapi
module load intel-classic/2023.2.0
module load fre/bronx-23
module load cray-hdf5/1.14.3.5
module load cray-netcdf/4.9.0.17
module load libyaml/0.2.5
module list

# Prepare next input files
bash $DSCR/setup_irlx_year_links.sh --yr ${yr} --jdir NEPirlx_${job_id}

FI_VERBS_PREFER_XRC=0
DEXE=/gpfs/f6/ira-cefi/scratch/Dmitry.Dukhovskoy/fre/NEP/hindcast_bgc/FMS2_MOM6_SIS2_BGC_compile_irlx/ncrc6.intel23-repro/exec
HEXE=fms_FMS2_MOM6_SIS2_BGC_compile_irlx.x

bash clean_oldrun.sh

/bin/rm -f \$HEXE
/bin/cp \$DEXE/\$HEXE .

/usr/bin/srun --ntasks=2036 --cpus-per-task=1 --export=ALL ./\${HEXE}

DOUT=NEPirlx_\$SLURM_JOB_ID
mkdir \$DOUT
for file in ????0101.*.nc; do
  [ -f "\$file" ] && mv "\$file" "\$DOUT/"
done

for mfl in SIS*irlx*.o* MOM_parameter_doc* SIS_parameter_doc* COBALT_parameter_doc* time_stamp.* MOM_IC*; do
  [ -f "\$mfl" ] && mv "\$mfl" "\$DOUT/"
done
if [ -d RESTART ]; then
  shopt -s nullglob
  files=(RESTART/*)
  if [ \${#files[@]} -gt 0 ]; then
    /bin/mv RESTART "\$DOUT"/.
  fi
  shopt -u nullglob
fi

EOF

  chmod +x "$wrapper_script"

  # Submit Job with Dependency 
  new_job_id=$(sbatch --dependency=afterok:${job_id} "$wrapper_script" | awk '{print $4}')
  if [[ -z "$new_job_id" ]]; then
    echo "ERROR: Failed to submit job for year $yr"
    exit 1
  fi

  echo "Submitted job for year $yr with dependency on Job ID: $job_id -> new Job ID: $new_job_id"
  job_id=$new_job_id  # Chain dependency

done

exit 0

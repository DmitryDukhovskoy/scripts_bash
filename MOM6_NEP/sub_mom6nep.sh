#!/bin/bash
##SBATCH --nodes=16
#SBATCH -n 2036
#SBATCH --time=2:00:00
#SBATCH --job-name="NEP_TEST"
#SBATCH --output=NEP_o.%j
#SBATCH --error=NEP_e.%j
#SBATCH --qos=normal
#SBATCH --partition=batch
#SBATCH --clusters=c5
#SBATCH --account=cefi
#SBATCH --export=ALL
## Usage: sbatch sub_mom6sis.sh
set -u

echo "Model started:  " `date`

export HEXE=fms_MOM6_SIS2_GENERIC_4P_compile_symm.x

# Avoid job errors because of filesystem synchronization delays
sync && sleep 1

#srun --tasks=2036 --cpus-per-task=1 ./${HEXE}
srun -n 2036 ./${HEXE}

mkdir NEP_$SLURM_JOB_ID
#mv 19* NEP_$SLURM_JOB_ID/.
mv NEP_o.$SLURM_JOB_ID NEP_$SLURM_JOB_ID/.
mv NEP_e.$SLURM_JOB_ID NEP_$SLURM_JOB_ID/.
mv MOM_parameter_doc.* NEP_$SLURM_JOB_ID/.
mv SIS_parameter_doc.* NEP_$SLURM_JOB_ID/.
mv ocean.stats* NEP_$SLURM_JOB_ID/.
mv seaice.stats* NEP_$SLURM_JOB_ID/.
mkdir NEP_$SLURM_JOB_ID/logs
mv logfile.0* NEP_$SLURM_JOB_ID/logs/.
mv *.available_diags NEP_$SLURM_JOB_ID/.
mv available_diags* NEP_$SLURM_JOB_ID/.
mv stocks.out NEP_$SLURM_JOB_ID/.
mv RESTART NEP_$SLURM_JOB_ID/.

echo "Model ended:    " `date`

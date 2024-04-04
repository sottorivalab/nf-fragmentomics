#!/bin/bash
#SBATCH --job-name=maya_lpWGS
#SBATCH --output=nextflow_tfbs_out.txt
#SBATCH --error=nextflow_tfbs_err.txt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-72:00:00
#SBATCH --mail-type=none

module load nextflow
nextflow run main.nf -params-file params.yaml -profile hpc -resume

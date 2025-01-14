#!/bin/bash
#SBATCH --job-name=JOBNAME
#SBATCH --output=output.txt
#SBATCH --error=error.txt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-72:00:00
#SBATCH --mail-type=none

nextflow run main.nf -params-file params.yaml -profile production,singularity -resume

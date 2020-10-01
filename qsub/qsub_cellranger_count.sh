#!/bin/bash
## Run count function of cell ranger align, process and quantify scRNAseq data. Takes one directory containing all fastqs or file containing list of directories with fastqs, one directory per line. Output location is optional. If not supplied, output will be stored in home directory.
## Caveat: If list of directories is supplied, it is assumed that each directory is a sample. If necassary, the directory name is used as a sample name for renaming purposes
## For easy usage, submit job with ./cellranger.sh script
## Usage: qsub ./qsub_cellranger_count.sh -v input=/path/to/file/or/directory,ref=/path/to/reference/transcriptome,output=/path/to/desired/output/location[optional],chem=sequencingchemistry[optional]

# Job Name
#PBS -N cellranger_count
# Resources, e.g. a total time of 15 hours...
#PBS -l walltime=15:00:00
# Resources, ... and one node with 4 processors:
#PBS -l nodes=1:ppn=8
#PBS -l mem=64gb
# stderr redirection
#PBS -e cellranger_count.err
# stdout redirection
#PBS -o cellranger_count.slog

# Source bashrc
source ~/.bashrc

module load bio/cellranger/3.0.2

# Load conda environment if requested
if [[ ! -z ${conda}  ]]; then
  conda activate ${conda}
fi

# Create sample slog
slog="${tmp_dir}/${sample}_cellranger.slog"

#################
## Cell Ranger ##
#################

echo "" >> ${slog}
echo "-------------" >> ${slog}
echo " Cell Ranger " >> ${slog}
echo "-------------" >> ${slog}
echo "" >> ${slog}

echo "Ready to run Cell Ranger" >> ${slog}
echo "" >> ${slog}
# Removed version printing as it is done automatically by cellranger
#echo "$(cellranger count --version)" >> ${slog}
#echo "" >> ${slog}

# Change to output directory
cd ${outdir}

# Run cell ranger per sample
for sample in $(cat ${sfile}) ; do
  echo "  Running Cell Ranger on: ${sample}" >> ${slog}
  cellranger count --id="${sample}_$(date +%Y%m%d)" \
                   --transcriptome=${ref} \
                   --fastqs=${tmp_dir} \
                   --sample=${sample} \
                   --expect-cells=1000 \
                   --chemistry=${chem} \
                   --localcores=8 >> ${slog}
done

echo "Cell ranger complete: $(date +%T)" >> ${slog}


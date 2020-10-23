#!/bin/bash
## Run CITE-Seq-count for RNAseq data. Takes one directory containing all fastqs or file containing list of directories with fastqs, one directory per line. Output location is optional. If not supplied, output will be stored in home directory.
## Caveat: If list of directories is supplied, it is assumed that each directory is a sample
## For easy usage, submit job with ./citeseq.sh script
## Usage: sbatch --export=sample=${sample},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},citeseq=${citeseq},conda=${conda},hashtag=${hashtag},answer=${answer},barcodes=${barcodes} ./slurm_citeseq_count.sh 

# Job Name
#SBATCH --job-name=Citeseq_count.$sample
# Resources, e.g. a total time of 15 hours...
#SBATCH --time=15:00:00
# Resources, ... and one node with 4 processors:
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --mem 100000
#SBATCH --mail-user=eleanor.fewings@bioquant.uni-heidelberg.de

# Source bashrc
source ~/.bashrc

# Load conda environment if requested
if [[ ! -z ${conda}  ]]; then
  conda activate ${conda}
fi

# Create sample log and output
slog="${tmp_dir}/${sample}_citeseq.log"
sout="${outdir}/${sample}_citeseq"

mkdir -p ${sout}

# Merge fastqs if there is more than one lane of seq
nlane=$(cat "${tmp_dir}/samples.tmp.txt" | grep ${sample} | grep "_R1" | wc -l )

if [ ${nlane} -gt 1 ] ; then

  #Create merged fastqs
  fq1="${tmp_dir}/merged_${sample}_R1.fastq.gz"
  fq2="${tmp_dir}/merged_${sample}_R2.fastq.gz"
  
  #Find fastqs to merge
  r1=$(cat "${tmp_dir}/samples.tmp.txt" | grep ${sample} | cut -f2 | grep "_R1" | paste -s -d" ")
  r2=$(cat "${tmp_dir}/samples.tmp.txt" | grep ${sample} | cut -f2 | grep "_R2" | paste -s -d" ")
  
  #Merge fqs
  cat ${r1} > ${fq1}
  cat ${r2} > ${fq2}

else
  fq1=$(cat "${tmp_dir}/samples.tmp.txt" | grep ${sample} | cut -f2 | grep "_R1" )
  fq2=$(cat "${tmp_dir}/samples.tmp.txt" | grep ${sample} | cut -f2 | grep "_R1" )
fi

# Find out if barcodes mode is implemented
if [[ ${answer} == "Y" ]] || [[ ${answer} == "y" ]] ; then

# Find out if barcodes are zipped
  if [[ ${barcodes} == *"arcodes.tsv.gz" ]] ; then
    bdir=$(dirname ${barcodes})
    unzipped="${bdir}/barcodes.tsv"
    gunzip -c ${barcodes} > ${unzipped}
  fi

  
  echo "" >> ${slog} 
  echo "Run command:" >> ${slog} 
  echo "CITE-seq-Count -R1 ${fq1} -R2 ${fq2}" >> ${slog} 
  echo "-t ${hashtag} -cbf 1 -cbl 16 -umif 17 -umil 28" >> ${slog} 
  echo "-wl ${unzipped} -cells 1000 -o ${sout}" >> ${slog} 
  echo "" >> ${slog} 
  
  # Count with whitelist
  CITE-seq-Count -R1 ${fq1} \
                 -R2 ${fq2} \
                 -t ${hashtag} \
                 -cbf 1 -cbl 16 -umif 17 -umil 28 \
                 -wl ${unzipped} \
                 -cells 1000 \
                 -o ${sout} &>> ${slog}
                 
  # Remove unzipped file
  if [[ ${barcodes} == *"arcodes.tsv.gz" ]] ; then
    rm ${unzipped}
  fi
  
else
  echo "" >> ${slog} 
  echo "Run command:" >> ${slog} 
  echo "CITE-seq-Count -R1 ${fq1} -R2 ${fq2}" >> ${slog} 
  echo "-t ${hashtag} -cbf 1 -cbl 16 -umif 17 -umil 28" >> ${slog} 
  echo "-cells 1000 -o ${sout}" >> ${slog} 
  echo "" >> ${slog} 
  
  # Count with cells feature
  CITE-seq-Count -R1 ${fq1} \
                 -R2 ${fq2} \
                 -t ${hashtag} \
                 -cbf 1 -cbl 16 -umif 17 -umil 28 \
                 -cells 1000 \
                 -o ${sout} &>> ${slog}
fi
               
#!/bin/bash

# Submission script accepting arguments for citeseq counts function
# Ellie Fewings, 25Sep2020

# Running:
# ./citeseq.sh -i <input file or directory> -o <output location>[optional] -t <hashtag oligos> -c <conda environment>[optional] -h <help>

# Source bashrc
source ~/.bashrc

# Set abort function
abort()
{
    echo "Uh oh. An error occurred."
    echo ""
    echo "Exiting..."
    exit 2
}

trap 'abort' SIGINT SIGTERM

set -e

# Set help function
helpFunction()
{
  echo ""
  echo "Program: citeseq count"
  echo ""
  echo "Version: 0.1"
  echo ""
  echo "Usage: ./citeseq.sh -i <input file or directory> -o <output location>[optional] -t <hashtag oligos> -c <conda environment>[optional] -h <help>"
  echo ""
  echo "Options:"
      echo -e "\t-i\tInput: Path to directory containing all fastqs or file containing list of directories with fastqs, one directory per line [required]"
      echo -e "\t-o\tOutput directory: Path to location where output will be generated [default=HOME]"
      echo -e "\t-t\tPath to csv containing hashtag antibody barcodes and respective names [required]"
      echo -e "\t-c\tConda environment: Name of conda environment with STAR installed (unless it is available on path) [default=PATH]"
      echo -e "\t-h\tHelp: Does what it says on the tin"
  echo ""
}

# Set default chemistry and output location
output="$HOME"

# Accept arguments specified by user
while getopts "i:o:t:c:h" opt; do
  case $opt in
    i ) input="$OPTARG"
    ;;
    o ) output="$OPTARG"
    ;;
    t ) hashtag="$OPTARG"
    ;;
    c ) conda="$OPTARG"
    ;;
    h ) helpFunction ; exit 0
    ;;
    * ) echo "Incorrect arguments" ; helpFunction ; abort
    ;;
  esac
done

# Check minimum number of arguments
if [ $# -lt 2 ]; then
  echo "Not enough arguments"
  helpFunction
  abort
fi

# If input or hashtags are missing report help function
if [[ "${input}" == "" || "${hashtag}" == "" ]]; then
  echo "Incorrect arguments."
  echo "Input and hashtag oligos are required."
  helpFunction
  abort
else
  input=$(realpath "${input}")
fi

# Load conda environment if requested
if [[ ! -z ${conda} ]]; then
  conda activate ${conda}
fi

# Create directory for log and output
if [[ -z ${output} ]]; then
    outdir=$(realpath "${HOME}/Citeseq_output_$(date +%Y%m%d)")
else
    outdir=$(realpath "${output}/Citeseq_align_output_$(date +%Y%m%d)")
fi

log="${outdir}/Citeseq_$(date +%Y%m%d).log"
mkdir -p ${outdir}

# Find submission location
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Create temporary directory
tmp_dir=$(mktemp -d -t tmp-XXXX-$(date +%Y%m%d) --tmpdir=${outdir})

# Find STAR
set +e
citeseq=$(which CITE-seq-Count)
set -e

if [[ ${citeseq} == "" ]] ; then
  echo "CITE-seq-Count not found on PATH. Please install or supply a conda environment"
  helpFunction
  abort
fi

echo "Running ./citeseq.sh" > ${log}
echo "" >> ${log}
echo "------------" >> ${log}
echo " Submission " >> ${log}
echo "------------" >> ${log}
echo "" >> ${log}
echo "Job name: Citeseq_count" >> ${log}
echo "Time allocated: 15:00:00" >> ${log}
echo "Time of submission: $(date +"%T %D")" >> ${log}
echo "Resources allocated: nodes=1:ppn=8" >> ${log}
echo "User: ${PBS_O_LOGNAME}" >> ${log}
echo "Log: ${log}" >> ${log}
echo "Input: ${input}" >> ${log}
echo "Hashtags: ${hashtag}" >> ${log}
echo "Output: ${outdir}" >> ${log}
echo "CITE-seq-Count: ${citeseq}" >> ${log}
echo "Environment: ${conda}" >> ${log}
echo "------------" >> ${log}


# Create list of unique samples on which to run analysis
echo "" >> ${log}
echo "Creating list of samples on which to run analysis" >> ${log}
tfile="${tmp_dir}/samples.tmp.txt"
sfile="${tmp_dir}/samples.txt"

# Check if input is file or directory
if [[ -d ${input} ]] ; then
    nfq=$(ls -1 ${input}/*fastq.gz | wc -l)
    # Check if directory contains fastqs
    if [ ${nfq} -gt 0 ] ; then 
      echo "" >> ${log}
      echo "Input directory contains ${nfq} fastq files" >> ${log}
      echo "" >> ${log}
      intype="directory"
      for fq in $(ls -1 ${input}/*fastq.gz) ; do
        sample=$(basename ${fq} | sed 's/_L.*/_/g' | sed 's/_S[1-9]*_//g' | sed 's/_[1-9].fastq.gz//g')
        echo -e "${sample}\t${fq}" >> ${tfile}
      done
    else 
      echo "ERROR: Input directory contains no fastq files" >> ${log}
      echo "Exiting" >> ${log}
      exit 1
    fi

# Check if input is file
elif [[ -f ${input} ]] ; then
  intype="file"
  while read dir ; do
    nfq=$(ls -1 ${dir}/*fastq.gz | wc -l)
    if [ ${nfq} -gt 0 ] ; then
      sample=$(basename ${dir})
      for fq in $(ls -1 ${dir}/*fastq.gz) ; do
        echo -e "${sample}\t${fq}" >> ${tfile}
      done
    else 
      echo "ERROR: Input directory ${dir} contains no fastq files" >> ${log}
      echo "Exiting" >> ${log}
      exit 1
    fi
  done < ${input}
fi

# Remove duplicates from samples file
cut ${tfile} -f1 | sort -u > ${sfile}

#Submit to cluster
while read sample ; do
  echo "Submitting to cluster: ${sample}" >> ${log}
  qsub "${loc}/qsub/qsub_citeseq_count.sh" -v sample=${sample},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},citeseq=${citeseq},conda=${conda},hashtag=${hashtag}
done < ${sfile}

#!/bin/bash

# Submission script accepting arguments for cellranger counts function
# Ellie Fewings, 22Jul2020

# Running:
# ./cellranger.sh -i <input file or directory> -r <reference trancriptome> -o <output location>[optional] -c <sequencing chemistry>[optional] -h <help>

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
  echo "Program: Cellranger count"
  echo ""
  echo "Version: 0.1"
  echo ""
  echo "Usage: ./cellranger.sh -i <input file or directory> -r <reference trancriptome> -o <output location>[optional] -c <sequencing chemistry>[optional] -h <help>"
  echo ""
  echo "Options:"
      echo -e "\t-i\tInput: Path to directory containing all fastqs or file containing list of directories with fastqs, one directory per line [required]"
      echo -e "\t-r\tReference transcriptome: Path to directory containing reference transcriptome [required]"
      echo -e "\t-o\tOutput directory: Path to location where output will be generated [default=$HOME]"
      echo -e "\t-c\tSequencing chemistry: Sequencing chemistry used in assay (see cellranger count --chemistry options for details). Should be left on 'autodetect' mode (default) unless error occurs [default=auto]"
      echo -e "\t-h\tHelp: Does what it says on the tin"
  echo ""
}

# Set default chemistry and output location
chem="auto"
output="$HOME"

# Accept arguments specified by user
while getopts "i:r:o:c:h" opt; do
  case $opt in
    i ) input="$OPTARG"
    ;;
    r ) ref="$OPTARG"
    ;;
    o ) output="$OPTARG"
    ;;
    c ) chem="$OPTARG"
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

# If bam or intervals are missing report help function
if [[ "${input}" == "" || "${ref}" == "" ]]; then
  echo "Incorrect arguments."
  echo "Input and reference are required."
  helpFunction
  abort
fi

# Submit job to cluster
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

qsub "${loc}/qsub_cellranger_count.sh" -v input=${input},ref=${ref},output=${output},chem=${chem}

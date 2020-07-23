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
#PBS -l nodes=1:ppn=4
# stderr redirection
#PBS -e cellranger_count.err
# stdout redirection
#PBS -o cellranger_count.log

################
## Create log ##
################

# Create directory for log and output
if [[ -z ${output} ]]; then
    outdir="${PBS_O_HOME}/cellranger_output_$(date +%Y%m%d)"
else
    outdir="${output}/cellranger_output_$(date +%Y%m%d)"
fi

mkdir -p ${outdir}

log="${outdir}/cellranger_count_$(date +%Y%m%d).log"

# Report to log
echo "Running ./cellranger_count.sh" > ${log}
echo "" >> ${log}
echo "------------" >> ${log}
echo " Submission " >> ${log}
echo "------------" >> ${log}
echo "" >> ${log}
echo "Job name: cellranger_count" >> ${log}
echo "Time allocated: 15:00:00" >> ${log}
echo "Time of submission: $(date +"%T %D")" >> ${log}
echo "Resources allocated: nodes=1:ppn=4" >> ${log}
echo "User: ${PBS_O_LOGNAME}" >> ${log}
echo "Log: ${log}" >> ${log}
echo "Input: ${input}" >> ${log}
echo "Reference trancriptome: ${ref}" >> ${log}
echo "Sequencing chemistry: ${chem}" >> ${log}
echo "Output: ${outdir}" >> ${log}

#########################
## Resources and Tools ##
#########################

# Load cell ranger module
module load bio/cellranger/3.0.2


###########
## Input ##
###########

echo "" >> ${log}
echo "-------" >> ${log}
echo " Input " >> ${log}
echo "-------" >> ${log}
echo "" >> ${log}

# Check if input is file or directory
if [[ -d ${input} ]] ; then
    nfq=$(ls -1 ${input}/*fastq.gz | wc -l)
    # Check if directory contains fastqs
    if [ ${nfq} -gt 0 ] ; then 
      echo "Input directory contains ${nfq} fastq files" >> ${log}
      intype="directory"
    else 
      echo "ERROR: Input directory contains no fastq files" >> ${log}
      exit 1
    fi
# Check if input is file
elif [[ -f ${input} ]] ; then
    # Create additional file containing all fastqs within the specified directories
    for fqdir in $(cat ${input}) ; do
      ls -1 ${fqdir}/*fastq.gz >> "${outdir}/fastqs.txt"
    done
    ndir=$(cat ${input} | wc -l)
    nfq=$(cat "${outdir}/fastqs.txt" | wc -l)
    # Check if directories contain fastqs
    if [ ${nfq} -gt 0 ] ; then 
      echo "Input file contains ${ndir} directories with a total of ${nfq} fastq files" >> ${log}
      intype="file"
    else 
      echo "ERROR: Input directories contain no fastq files" >> ${log}
      exit 1
    fi
# If input is not file or direcory, report error and exit
else
    echo "ERROR: input `${input}` is not valid. Please specify a directory containing fastqs or a file containing a list of directories with fastqs" >> ${log}
    exit 1
fi

##################
## Format input ##
##################

# Create temporary directory
tmp_dir=$(mktemp -d -t tmp-XXXX-$(date +%Y%m%d) --tmpdir=${outdir})

echo "" >> ${log}
echo "Checking format of fastq files and renaming if necessary..." >> ${log}
echo "  Began: $(date +%T)" >> ${log}
echo "" >> ${log}

# Create list of unique samples on which to run analysis
echo "  Creating list of samples on which to run analysis" >> ${log}
tfile="${tmp_dir}/samples.tmp.txt"
sfile="${tmp_dir}/samples.txt"

# File containing old and new names for log purposes
names="${outdir}/renamed_fastqs_$(date +%Y%m%d).txt"
echo -e "OldFQ\tNewFQ" > ${names}
echo "  Any file name changes will be recorded in: ${names}" >> ${log}

# Formatting data for input into cellranger. Gather files into one directory and rename if necassary

# If input supplied is a file of multiple directories: move fastqs to tmp directory and reformat names to match BCL2FASTQ format
if [[ ${intype} == "file" ]] ; then
  while read fqdir ; do
    for fq in $(ls -1 ${fqdir}/*fastq.gz) ; do
        # Copy file straight over if name is in correct format
        if [[ ${fq} == *"_S"* ]] && [[ ${fq} == *"_L00"* ]] && [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_R2"* ) || ( ${fq} == *"_I1"* )]] ; then
          sample=$(basename ${fq} | sed 's/_L.*//g' | sed 's/_S[1:9]//g' | sed 's/_[1:9].fastq.gz//g')
          echo "${sample}" >> ${tfile}
          cp ${fq} ${tmp_dir}
          echo -e "${fq}\t${tmp_dir}$(basename ${fq})" >> ${names}
        else
          echo "    Incorrect fastq naming format for ${fq}. Renaming file" >> ${log}
          # Infer sample name from directory name
          sample=$(basename ${fqdir})
          # Infer lane number
          if [ $(ls -1 ${fqdir}/*fastq.gz | wc -l) -gt 2 ] ; then
            oldlane=$(basename ${fq} | sed 's+.*L+L+' | cut -d'_' -f1)
            if [[ ${oldlane} == *"1" ]] ; then
              lane="L001"
            elif [[ ${oldlane} == *"2" ]] ; then
              lane="L002"
            elif [[ ${oldlane} == *"3" ]] ; then
              lane="L003"
            elif [[ ${oldlane} == *"4" ]] ; then
              lane="L004"
            else echo "  ERROR: Cannot infer lane number for renaming of file: ${fq}" >> ${log}
              echo "  Please manually rename file to contain lane number (i.e. L001)" >> ${log}
              exit 1
            fi
          else
            lane="L001"
          fi
          # Infer read number
          if [[ ( ${fq} == *"_I1"* ) ]] ; then
            read="I1"
          elif [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_1_"* ) || ( ${fq} == *"_1."* ) ]] ; then
            read="R1"
          elif [[ ( ${fq} == *"_R2"* ) || ( ${fq} == *"_2_"* ) || ( ${fq} == *"_2."* ) ]] ; then
            read="R2"
          else echo "  ERROR: Cannot infer read number for renaming of file: ${fq}" >> ${log}
            echo "  Please manually rename file to contain read number (i.e. R1)" >> ${log}
            exit 1 
          fi
        # Copy file with new name to tmp directory and record name change
        newname="${tmp_dir}/${sample}_S1_${lane}_${read}_001.fastq.gz"
        echo -e "${fq}\t${newname}" >> ${names}
        cp ${fq} ${newname}
        echo "${sample}" >> ${tfile}
      fi
    done
  done < ${input}
fi

# If input supplied is a directory: move fastqs to tmp directory and reformat names to match BCL2FASTQ format if necassary
if [[ ${intype} == "directory" ]] ; then
  for fq in $(ls -1 ${input}/*fastq.gz) ; do
    # Copy file if file name is in correct format
    if [[ ${fq} == *"_S"* ]] && [[ ${fq} == *"_L00"* ]] && [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_R2"* ) || ( ${fq} == *"_I1"* ) ]] ; then
      sample=$(basename ${fq} | sed 's/_L.*//g' | sed 's/_S[1:9]//g' | sed 's/_[1:9].fastq.gz//g')
      echo "${sample}" >> ${tfile}
      echo -e "${fq}\t${tmp_dir}$(basename ${fq})" >> ${names}
      cp ${fq} ${tmp_dir}
    else
      echo "  Incorrect fastq naming format for ${fq}. Renaming file" >> ${log}
      # Infer sample name from previous file name
      sample=$(basename ${fq} | sed 's/_L.*//g' | sed 's/_S[1:9]//g' | sed 's/_[1:9].fastq.gz//g')
      # Infer lane number
      if [ $(ls -1 ${input}/${sample}*fastq.gz | wc -l) -gt 2 ] ; then
        oldlane=$(basename ${fq} | sed 's+.*L+L+' | cut -d'_' -f1)
        if [[ ${oldlane} == *"1" ]] ; then
          lane="L001"
        elif [[ ${oldlane} == *"2" ]] ; then
          lane="L002"
        elif [[ ${oldlane} == *"3" ]] ; then
          lane="L003"
        elif [[ ${oldlane} == *"4" ]] ; then
          lane="L004"
        else echo "  ERROR: Cannot infer lane number for renaming of file: ${fq}" >> ${log}
          echo "  Please manually rename file to contain lane number (i.e. L001)" >> ${log}
          exit 1
        fi
      else
        lane="L001"
      fi
      # Infer read number
      if [[ ( ${fq} == *"_I1"* ) ]] ; then
        read="I1"
      elif [[ ( ${fq} == *"_R1"* ) || ( ${fq} == *"_1_"* ) || ( ${fq} == *"_1."* ) ]] ; then
        read="R1"
      elif [[ ( ${fq} == *"_R2"* ) || ( ${fq} == *"_2_"* ) || ( ${fq} == *"_2."* ) ]] ; then
        read="R2"
      else echo "  ERROR: Cannot infer read number for renaming of file: ${fq}" >> ${log}
        echo "  Please manually rename file to contain read number (i.e. R1)" >> ${log}
        exit 1 
      fi
      # Copy file with new name to tmp directory and record name change
      newname="${tmp_dir}/${sample}_S1_${lane}_${read}_001.fastq.gz"
      echo -e "${fq}\t${newname}" >> ${names}
      cp ${fq} ${newname}
      echo "${sample}" >> ${tfile}
    fi
  done
fi

# Remove duplicates from samples file
cat ${tfile} | sort -u > ${sfile}

echo "" >> ${log}
echo "Finished moving and renaming fastqs" >> ${log}
echo "" >> ${log}
# Check new input directory for a R1 and R2 per sample and lane

echo "Checking if each file has a forward and reverse read pair..." >> ${log}
echo "" >> ${log}

for fq in $(ls -1 ${tmp_dir}/*fastq.gz) ; do
  # Find name of read pair file
  if [[ ${fq} == *"R1"* ]] ; then
    pair=$(echo ${fq} | sed 's+R1+R2+')
  elif [[ ${fq} == *"R2"* ]] ; then
    pair=$(echo ${fq} | sed 's+R2+R1+')
  fi
  # Check if read pair file exists
  if [ ! -f ${pair} ] ; then 
    echo "  ERROR: Read pair doesn't exist for fastq: ${fq}" >> ${log}
    echo "  Please check if pair exists and manually rename if files don't fit normal naming conventions (i.e. R1, R2)" >> ${log}
    exit 1
  fi
done

echo "Completed all file checks: $(date +%T)" >> ${log}
echo "" >> ${log}

#################
## Cell Ranger ##
#################

echo "" >> ${log}
echo "-------------" >> ${log}
echo " Cell Ranger " >> ${log}
echo "-------------" >> ${log}
echo "" >> ${log}

echo "Ready to run Cell Ranger" >> ${log}
echo "" >> ${log}
# Removed version printing as it is done automatically by cellranger
#echo "$(cellranger count --version)" >> ${log}
#echo "" >> ${log}

# Change to output directory
cd ${outdir} 

# Run cell ranger per sample
for sample in $(cat ${sfile}) ; do
  echo "  Running Cell Ranger on: ${sample}" >> ${log}
  cellranger count --id="${sample}_$(date +%Y%m%d)" \
                   --transcriptome=${ref} \
                   --fastqs=${tmp_dir} \
                   --sample=${sample} \
                   --expect-cells=1000 \
                   --chemistry=${chem} \
                   --localcores=4 >> ${log}
done

echo "Cell ranger complete: $(date +%T)" >> ${log}

###############
## Finishing ##
###############

echo "" >> ${log}
echo "--------" >> ${log}
echo " Output " >> ${log}
echo "--------" >> ${log}
echo "" >> ${log}

echo "Checking output directories" >> ${log}
echo "" >> ${log}

# Check there is an output for all samples
for sample in $(cat ${sfile}) ; do
  outs=$(ls -d1 ${outdir}/${sample}*/outs/)
  if [ $(echo ${outs} | wc -l) -gt 0 ] ; then
    echo "  Output for ${sample}: $(dirname ${outs})" >> ${log}
  else
    echo "  Cannot find output for ${sample}. Check log for any errors" >> ${log}
  fi
done

echo "" >> ${log}
echo "Cellranger counts pipeline complete. Congratulations :D" >> ${log}
echo "Time of completion: $(date +"%T %D")" >> ${log}
echo "">> ${log}


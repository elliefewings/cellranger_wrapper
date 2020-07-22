# Cellranger wrapper

###Wrapper for submission of cellranger counts to qsub system

##            Usage

This wrapper was written with the intention of being used on the University of Heidelberg BioQuant cluster

```
$ ./cellranger.sh

Program: Cellranger count

Version: 0.1

Usage: ./cellranger.sh -i <input file or directory> -r <reference trancriptome> -o <output location>[optional] -c <sequencing chemistry>[optional] -h <help>

Options:
        -i      Input: Path to directory containing all fastqs or file containing list of directories with fastqs, one directory per line [required]
        -r      Reference transcriptome: Path to directory containing reference transcriptome [required]
        -o      Output directory: Path to location where output will be generated [default=/home/bq_efewings]
        -c      Sequencing chemistry: Sequencing chemistry used in assay (see cellranger count --chemistry options for details). Should be left on 'autodetect' mode (default) unless error occurs [default=auto]
        -h      Help: Does what it says on the tin
```
## Input

The input can be either the path to one directory containing multiple fastqs, or the path to a text file containing a list of directories. When supplying a file containing a list of fastq-containing directories, it is assumed that the directory name is the name of the sample to be analysed. 



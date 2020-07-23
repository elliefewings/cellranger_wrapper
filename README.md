# Cell Ranger wrapper

### Wrapper for submission of cellranger counts to qsub system

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

Example input file:
```
$head input.txt
/home/directory/sample1
/home/directory/sample2
/home/directory/sample3

$ ls /home/directory/sample1
sample1_S1_L001_R1_001.fastq.gz sample1_S1_L001_R2_001.fastq.gz
sample1_S1_L002_R1_001.fastq.gz sample1_S1_L002_R2_001.fastq.gz

```
Example input directory:
```
$ ls /home/directory/input
sample1_S1_L001_R1_001.fastq.gz sample1_S1_L001_R2_001.fastq.gz
sample1_S1_L002_R1_001.fastq.gz sample1_S1_L002_R2_001.fastq.gz
sample1_S2_L001_R1_001.fastq.gz sample1_S2_L001_R2_001.fastq.gz
sample1_S2_L002_R1_001.fastq.gz sample1_S2_L002_R2_001.fastq.gz
sample1_S3_L001_R1_001.fastq.gz sample1_S3_L001_R2_001.fastq.gz
sample1_S3_L002_R1_001.fastq.gz sample1_S3_L002_R2_001.fastq.gz
```
## Reference

A reference transcriptome is required for alignment. [Prebuilt references](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest) for human (GRCh38) and mouse (mm10) are supplied by Cell Ranger.

You can also follow [instructions](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/tutorial_mr) to make your own reference.

## Sequencing Chemistry

It is recommended that you leave this setting on default unless an error occurs.

As default, Cell Ranger automatically detects assay configuration. However there may be occasions where automatic detection is not possible. In which case please specify one of the following options:

+ `threeprime` for Single Cell 3′,
+ `fiveprime` for Single Cell 5′,
+ `SC3Pv2` for Single Cell 3′ v2,
+ `SC3Pv3` for Single Cell 3′ v3,
+ `SC5P-PE` for Single Cell 5′ paired-end (both R1 and R2 are used for alignment),
+ `SC5P-R2` for Single Cell 5′ R2-only (where only R2 is used for alignment).
+ `SC3Pv1` for Single Cell 3′ v1. NOTE: this mode cannot be auto-detected. It must be set explicitly with this option

## Output

You can set an output directory with this option, by default data will be stored in your $HOME directory.

## Output files 
### [From Cell Ranger guide](https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/count)

A successful `cellranger count` run should conclude with a message similar to this (this will be found in the log file written in the output directory):
```
Outputs:
- Run summary HTML:                         /opt/sample345/outs/web_summary.html
- Run summary CSV:                          /opt/sample345/outs/metrics_summary.csv
- BAM:                                      /opt/sample345/outs/possorted_genome_bam.bam
- BAM index:                                /opt/sample345/outs/possorted_genome_bam.bam.bai
- Filtered feature-barcode matrices MEX:    /opt/sample345/outs/filtered_feature_bc_matrix
- Filtered feature-barcode matrices HDF5:   /opt/sample345/outs/filtered_feature_bc_matrix.h5
- Unfiltered feature-barcode matrices MEX:  /opt/sample345/outs/raw_feature_bc_matrix
- Unfiltered feature-barcode matrices HDF5: /opt/sample345/outs/raw_feature_bc_matrix.h5
- Secondary analysis output CSV:            /opt/sample345/outs/analysis
- Per-molecule read information:            /opt/sample345/outs/molecule_info.h5
- CRISPR-specific analysis:                 null
- Loupe Browser file:                       /opt/sample345/outs/cloupe.cloupe
- Feature Reference:                        null
- Target Panel File:                        null
Waiting 6 seconds for UI to do final refresh.
Pipestance completed successfully!


yyyy-mm-dd hh:mm:ss Shutting down.
Saving pipestance info to "tiny/tiny.mri.tgz"
```
The output of the pipeline will be contained in the output directory specified above. There will be a subfolder named with the samples you specified and the date they were run (e.g. sample1_20200101, sample2_20200101). Each subfolder will contain an `outs` directory containing the main pipeline output files:

| File Name        | Description           |
| ------------- |-------------|
| web_summary.html | Run summary metrics and charts in HTML format |
| metrics_summary.csv | Run summary metrics in CSV format |
| possorted_genome_bam.bam | Reads aligned to the genome and transcriptome annotated with barcode information |
| possorted_genome_bam.bam.bai | Index for possorted_genome_bam.bam |
| filtered_feature_bc_matrix | Filtered feature-barcode matrices containing only cellular barcodes in MEX format. (In Targeted Gene Expression samples, the non-targeted genes are not present.) |
| filtered_feature_bc_matrix_h5.h5 | Filtered feature-barcode matrices containing only cellular barcodes in HDF5 format. (In Targeted Gene Expression samples, the non-targeted genes are not present.) |
| raw_feature_bc_matrices | Unfiltered feature-barcode matrices containing all barcodes in MEX format |
| raw_feature_bc_matrix_h5.h5 | Unfiltered feature-barcode matrices containing all barcodes in HDF5 format |
| analysis | Secondary analysis data including dimensionality reduction, cell clustering, and differential expression |
| molecule_info.h5 | Molecule-level information used by cellranger aggr to aggregate samples into larger datasets |
| cloupe.cloupe | Loupe Browser visualization and analysis file |
| feature_reference.csv | (Feature Barcode only) Feature Reference CSV file |
| target_panel.csv | (Targeted GEX only) Targed panel CSV file |

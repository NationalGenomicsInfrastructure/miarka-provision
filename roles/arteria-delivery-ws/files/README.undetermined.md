# DELIVERY OF FASTQ FILES FROM NGI-UPPSALA,THE SNP&SEQ TECHNOLOGY PLATFORM

This delivery includes sequencing data in FASTQ format, a summary report created with MultiQC, checksums and a copy of the sample sheet used for demultiplexing. 

## Delivery structure
```
<project>
└── <runfolder>
    ├── README.md
    ├── checksums.md5
    ├── SampleSheet.csv
    ├── <runfolder>_<project>_multiqc_report_data.zip
    ├── <runfolder>_<project>_multiqc_report.html
    ├── <Sample1 id>
        ├── <sample1 name>_<sample number>_R1_001.fastq.gz
        └── <sample1 name>_<sample number>_R2_001.fastq.gz 
    ├── <Sample2 id>
        ├── <sample2 name>_<sample number>_R1_001.fastq.gz
        └── <sample2 name>_<sample number>_R2_001.fastq.gz
     :
     :
    └── <SampleN id>
        ├── <sampleN name>_<sample number>_R1_001.fastq.gz
        └── <sampleN name>_<sample number>_R2_001.fastq.gz
    └── Undetermined 
        ├── Undetermined_<sample number>_<lane>_R1.001.fastq.gz
        ├── Undetermined_<sample number>_<lane>_R2.001.fastq.gz
        ├── ...
        └── checksums.md5
```

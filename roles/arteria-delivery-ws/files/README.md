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
```

## Verifying file integrity
It is strongly encouraged to verify file integrity after delivery. It can be done with the following commands:
```
cd <project>
md5sum -c <runfolder>/checksums.md5
```
If the verification fails, please try to download the data again. If the issue persists, please contact the SNP&SEQ Technology Platform.

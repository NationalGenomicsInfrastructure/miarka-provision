# DELIVERY OF FASTQ FILES FROM NGI-UPPSALA,THE SNP&SEQ TECHNOLOGY PLATFORM

This delivery includes sequencing data in FASTQ format, a summary report created with MultiQC, checksums and a copy of the sample sheet used for demultiplexing.

The FASTQ files named "Undetermined" contains reads that could not be assigned to a sample. Note that in cases where demultiplexing is expected to fail e.g. when inline barcode are used, the Undetermined FASTQs are the main data source. There might be some reads assigned to individual sample(s) (i.e. <Sample1 id> ... <SampleN id>) by chance. These can be disregarded.

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

## Verifying file integrity
It is strongly encouraged to verify file integrity after delivery. Since Undetermined FASTQs are added ad-hoc to normal processing, checksums for those files are stored in a separate file. To verify all files (including Undetermined), execute the following commands:
```
cd <project>
md5sum -c <runfolder>/checksums.md5

cd <runfolder>/Undetermined
md5sum -c checksums.md5
```
If the verification fails, please try to download the data again. If the issue persists, please contact the SNP&SEQ Technology Platform.


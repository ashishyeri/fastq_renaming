# Test data for -profile test

Place small FASTQ files here for a test run, or create minimal gzipped FASTQs.

Example Illumina-style names for testing sample extraction and merge:

- `Sample1_S1_L001_R1_001.fastq.gz`
- `Sample1_S1_L002_R1_001.fastq.gz` (same sample, lane 2)
- `Sample1_S1_L001_R2_001.fastq.gz`
- `Sample1_S1_L002_R2_001.fastq.gz`

Minimal valid FASTQ (4 lines per read):

```
@read1
ACGT
+
!!!!
```

Then: `gzip -c minimal.fastq > Sample1_S1_L001_R1_001.fastq.gz`

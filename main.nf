// Nextflow FASTQ pipeline: extract sample names, merge lanes, run FastQC.
// Run: nextflow run main.nf -c config/paths.config -profile conda
// Test: nextflow run main.nf -c config/paths.config -profile test,conda

include { createGroupedFastqChannel } from './modules/input.nf'
include { MERGE_FASTQ } from './modules/merge_fastq.nf'
include { FASTQC } from './modules/fastqc.nf'

params.input_fastq_glob = null
params.sample_naming_convention = 'illumina'
params.merged_fastq_dir = "${params.storage_root}/large_files/merged_fastq"
params.publish_fastqc_dir = "${params.storage_root}/large_files/fastqc"
params.fastqc_extra = ''

workflow {
    if (!params.input_fastq_glob) {
        exit 1, "Set input FASTQ glob, e.g. --input_fastq_glob 'path/to/*.fastq.gz' or use -profile test"
    }

    fastq_ch = createGroupedFastqChannel(params.input_fastq_glob, params.sample_naming_convention)
    MERGE_FASTQ(fastq_ch)
    FASTQC(MERGE_FASTQ.out.merged)
}

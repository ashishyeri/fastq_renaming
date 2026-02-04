process MERGE_FASTQ {
    tag "${sample_id}_${read}"
    label 'merge'
    publishDir params.merged_fastq_dir, mode: 'copy', saveAs: { it.name }

    input:
    tuple val(sample_id), val(read), path(fastqs)

    output:
    path("${sample_id}_${read}.fastq.gz"), emit: merged

    script:
    def files = fastqs.sort()
    def n = files.size()
    if (n == 1) {
        """
        cp "${files[0]}" "${sample_id}_${read}.fastq.gz"
        test -s "${sample_id}_${read}.fastq.gz" || (echo "Merge failed: empty or missing output" && exit 1)
        """
    } else {
        """
        zcat ${files.join(' ')} | gzip -c > "${sample_id}_${read}.fastq.gz"
        test -s "${sample_id}_${read}.fastq.gz" || (echo "Merge failed: empty or missing output" && exit 1)
        """
    }

    conda 'fastqc'
}

process FASTQC {
    tag fastq.name
    label 'fastqc'
    publishDir params.publish_fastqc_dir, mode: 'copy', pattern: '*.{html,zip}'

    input:
    path(fastq)

    output:
    path("*.html"), emit: html
    path("*.zip"),  emit: zip

    script:
    """
    fastqc -o . --noextract -f fastq "${fastq}"
    test -n "\$(ls *.html 2>/dev/null)" && test -n "\$(ls *.zip 2>/dev/null)" || (echo "FastQC failed: missing output" && exit 1)
    """

    conda 'fastqc'
}

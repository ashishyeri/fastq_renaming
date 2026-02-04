/**
 * Sample name extraction from FASTQ filenames for multiple naming conventions.
 * Used by the pipeline to group files by sample and read (R1/R2).
 */

// Illumina: SampleName_S1_L001_R1_001.fastq.gz -> SampleName
// Match up to (but not including) _S\d+_L
static String getSampleIdFromIllumina(String path) {
    def name = path instanceof File ? path.name : new File(path as String).name
    def m = name =~ /^(.+?)_S\d+_L\d+/
    if (m.find()) return m.group(1)
    return name.replaceAll(/\\.(fastq|fq)(\\.gz)?$/, '')
}

// Generic: strip _L*_R*_* (lane, read, segment) and extension
static String getSampleIdGeneric(String path) {
    def name = path instanceof File ? path.name : new File(path as String).name
    def noExt = name.replaceAll(/\\.(fastq|fq)(\\.gz)?$/, '')
    return noExt.replaceFirst(/_L\\d+_R\\d+_\\d+$/, '').replaceFirst(/_L\\d+_R\\d+$/, '')
}

// First token: first underscore-delimited component (e.g. sample_lane1_R1.fq.gz -> sample)
static String getSampleIdFirstToken(String path) {
    def name = path instanceof File ? path.name : new File(path as String).name
    def noExt = name.replaceAll(/\\.(fastq|fq)(\\.gz)?$/, '')
    return noExt.split('_')[0] ?: noExt
}

// Dispatcher: convention = 'illumina' | 'generic' | 'first_token'
static String getSampleId(path, String convention) {
    def c = (convention ?: 'illumina').toLowerCase()
    if (c == 'generic') return getSampleIdGeneric(path)
    if (c == 'first_token') return getSampleIdFirstToken(path)
    return getSampleIdFromIllumina(path)
}

// Infer read (R1, R2, etc.) from filename for grouping
static String getReadFromPath(String path) {
    def name = path instanceof File ? path.name : new File(path as String).name
    def m = name =~ /_R([12])[_\\.]/
    if (m.find()) return "R${m.group(1)}"
    if (name.contains('_R1') || name.contains('.R1.') || name.contains('_1.') || name.contains('_1_')) return 'R1'
    if (name.contains('_R2') || name.contains('.R2.') || name.contains('_2.') || name.contains('_2_')) return 'R2'
    return 'R1'  // default single-end as R1
}

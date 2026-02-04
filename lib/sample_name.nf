// Sample name and read extraction from FASTQ filenames.
// Include in pipeline: include { getSampleId, getReadFromPath } from './lib/sample_name.nf'

def getSampleIdFromIllumina(path) {
    def name = path instanceof Path ? path.name : path.toString().split('/')[-1]
    def m = (name =~ /^(.+?)_S\d+_L\d+/)
    if (m.find()) return m.group(1)
    return name.replaceAll(/\.(fastq|fq)(\.gz)?$/, '')
}

def getSampleIdGeneric(path) {
    def name = path instanceof Path ? path.name : path.toString().split('/')[-1]
    def noExt = name.replaceAll(/\.(fastq|fq)(\.gz)?$/, '')
    return noExt.replaceFirst(/_L\d+_R\d+_\d+$/, '').replaceFirst(/_L\d+_R\d+$/, '')
}

def getSampleIdFirstToken(path) {
    def name = path instanceof Path ? path.name : path.toString().split('/')[-1]
    def noExt = name.replaceAll(/\.(fastq|fq)(\.gz)?$/, '')
    return noExt.split('_')[0] ?: noExt
}

def getSampleId(path, convention) {
    def c = (convention ?: 'illumina').toLowerCase()
    if (c == 'generic') return getSampleIdGeneric(path)
    if (c == 'first_token') return getSampleIdFirstToken(path)
    return getSampleIdFromIllumina(path)
}

def getReadFromPath(path) {
    def name = path instanceof Path ? path.name : path.toString().split('/')[-1]
    def m = (name =~ /_R([12])[_.]/)
    if (m.find()) return "R${m.group(1)}"
    if (name.contains('_R1') || name.contains('.R1.') || name.contains('_1.') || name.contains('_1_')) return 'R1'
    if (name.contains('_R2') || name.contains('.R2.') || name.contains('_2.') || name.contains('_2_')) return 'R2'
    return 'R1'
}

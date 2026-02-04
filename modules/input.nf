// Builds channel of (sample_id, read, list of fastq paths) from input glob.
include { getSampleId, getReadFromPath } from '../lib/sample_name.nf'

def createGroupedFastqChannel(input_glob, convention) {
    Channel.fromPath(input_glob, checkIfExists: true)
        .map { path -> tuple(getSampleId(path, convention), getReadFromPath(path), path) }
        .groupTuple(by: [0, 1])
        .map { sample_id, read, files -> tuple(sample_id, read, files.sort()) }
}

//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    ch_samplesheet    // channel: [ val(meta), /path/to/reads ]

    main:
    ch_versions = Channel.empty()

    // Create the samplesheet channel
    ch_samplesheet
        .map { meta, datafile -> create_data_channel( meta, datafile ) }
        .set { vcf }


    emit:
    vcf                            // channel: [ val(meta), /path/to/datafile ]
    versions = ch_versions         // channel: [ versions.yml                 ]
}

// Function to get list of [ meta, VCF ]
def create_data_channel ( LinkedHashMap row, datafile ) {
    // create meta map
    def meta    = [:]
    meta.id     = row.sample
    // meta.sample = row.sample.split('_')[0..-2].join('_')
    meta.datatype   = row.datatype
    // meta.file   = row.datafile

    // Convert datafile to string path and then split
    // def datafile_path = datafile.toString()
    // meta.vcf_group  = "\'@RG\\tID:" + datafile_path.split('/')[-1].split('\\.')[0..-2].join('.') + "\\tPL:" + "\\tSM:" + meta.sample + "\'"
    // println(meta.vcf_group)
    def file_name = datafile.toString()
    meta.datafile = file_name.split('/')[-1].split('\\.')[0..-2].join('.')

    // add path(s) of the VCF file(s) to the meta map
    def data_meta = []
    if ( !file(row.datafile).exists() ) {
        exit 1, "ERROR: Please check input samplesheet -> Data file does not exist.\n${row.datafile}"
    } else {
        data_meta = [ meta, file(row.datafile) ]
    }
    return data_meta
}

include { VCFTOOLS     as VCFTOOLS_ALLELE_FREQUENCY }   from '../../../modules/nf-core/vcftools/main'
include { BCFTOOLS_ROH as BCFTOOLS_ROH              }   from '../../../modules/nf-core/bcftools/roh/main'

workflow AF_ROH {
    take:
    samplesheet        // channel: [ meta, VCF/gVCF ]
    vcfs_tbi           // channel: [ meta, VCF/gVCF, tbi ]

    main:
    ch_versions = channel.empty()

    // Call VCFtools for allele frequency
    VCFTOOLS_ALLELE_FREQUENCY( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_ALLELE_FREQUENCY.out.versions )

    // Call BCFtools for ROH
    BCFTOOLS_ROH( vcfs_tbi, [ [], [] ], [], [], [], [] )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )

    emit:
    allele_frequency    = VCFTOOLS_ALLELE_FREQUENCY.out.frq    // channel: [ meta, allele_frequency ]
    roh                 = BCFTOOLS_ROH.out.roh                 // channel: [ meta, roh              ]
    versions            = ch_versions                          // channel: [ versions.yml           ]

}

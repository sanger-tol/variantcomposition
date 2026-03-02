include { VCFTOOLS         as VCFTOOLS_ALLELE_FREQUENCY }   from '../../../modules/nf-core/vcftools/main'
include { TABIX_BGZIP      as BGZIP                     }   from '../../../modules/nf-core/tabix/bgzip/main'
include { TABIX_TABIX      as TABIX_AF                  }   from '../../../modules/nf-core/tabix/tabix/main'
include { BCFTOOLS_ROH     as BCFTOOLS_ROH              }   from '../../../modules/nf-core/bcftools/roh/main'
include { BCFTOOLS_ROHVIZ  as BCFTOOLS_ROHVIZ           }   from '../../../modules/local/rohviz/main'

workflow AF_ROH {
    take:
    samplesheet        // channel: [ meta, VCF/gVCF ]
    vcfs_tbi           // channel: [ meta, VCF/gVCF, tbi ]

    main:
    ch_versions = channel.empty()

    // Call VCFtools for allele frequency
    VCFTOOLS_ALLELE_FREQUENCY( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_ALLELE_FREQUENCY.out.versions )

    // Compress allele frequency output file
    BGZIP ( VCFTOOLS_ALLELE_FREQUENCY.out.frq )
    ch_versions = ch_versions.mix ( BGZIP.out.versions.first() )

    // Index the compressed .pi files
    TABIX_AF ( BGZIP.out.output )
    ch_versions = ch_versions.mix ( TABIX_AF.out.versions )

    // Prepare for input channels of BCFtools RoH
    // Generate a key (meta.id) to match VCF/gVCF files and allele frequency results
    def vcfs_tbi_keyed = vcfs_tbi
        .map { meta, vcfs, tbi -> [ meta.id, meta, vcfs, tbi ] }

    def af_tbi_keyed = BGZIP.out.output
        .join( TABIX_AF.out.tbi )
        .map{ meta, af, aftbi -> [ meta.id, af, aftbi ] }

    // Gather VCF/gVCF files and allele frequency results as matched inputs for BCFtools RoH
    def ch_vcfs_af_joined = vcfs_tbi_keyed
        .join(af_tbi_keyed)

    // Call BCFtools for ROH
    BCFTOOLS_ROH(
        ch_vcfs_af_joined.map{ _meta_id, meta, vcfs, vcf_tbi, _af, _af_tbi -> [ meta, vcfs, vcf_tbi] },
        ch_vcfs_af_joined.map{ _meta_id, _meta, _vcfs, _vcf_tbi, af, af_tbi -> [ af, af_tbi] },
        [],
        [],
        [],
        []
    )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )

    BCFTOOLS_ROHVIZ ( BCFTOOLS_ROH.out.roh, samplesheet, [], [], [] )
        ch_versions = ch_versions.mix(
        BCFTOOLS_ROHVIZ.out.versions_bcftools
            .map { process, tool, version ->
            // convert tuple to YAML string
            "${process}:\n  ${tool}: ${version}"
            }
    )

    emit:
    compressed_allele_frequency = BGZIP.out.output            // channel: [ meta, output ]
    allele_frequency_tbi        = TABIX_AF.out.tbi            // channel: [ meta, tbi    ]
    roh                         = BCFTOOLS_ROH.out.roh        // channel: [ meta, roh    ]
    roh_viz                     = BCFTOOLS_ROHVIZ.out.output  // channel: [ meta, output ]
    versions                    = ch_versions                 // channel: [ versions.yml ]

}

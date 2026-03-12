include { BCFTOOLS_QUERY   as BCFTOOLS_QUERY            }   from '../../../modules/nf-core/bcftools/query/main'
include { BGZIPTABIX       as BGZIPTABIX_AF_FILE        }   from '../../../modules/sanger-tol/bgziptabix/main'
include { BCFTOOLS_ROH     as BCFTOOLS_ROH              }   from '../../../modules/nf-core/bcftools/roh/main'
include { BCFTOOLS_ROHVIZ  as BCFTOOLS_ROHVIZ           }   from '../../../modules/local/rohviz/main'

workflow AF_ROH {
    take:
    samplesheet        // channel: [ meta, VCF/gVCF ]
    vcfs_tbi           // channel: [ meta, VCF/gVCF, tbi ]

    main:
    ch_versions = channel.empty()

    // Prepare for input channels of BCFtools RoH
    // Create the AF-file input using bcftools query
    BCFTOOLS_QUERY ( vcfs_tbi, [], [], [] )
    params.max_seq_length = 0
    BGZIPTABIX_AF_FILE ( BCFTOOLS_QUERY.out.output
        .map { meta, input -> [ meta, input, params.max_seq_length ]}
    )
    // Generate a key (meta.id) to match VCF/gVCF files and allele frequency results
    def vcfs_tbi_keyed = vcfs_tbi
        .map { meta, vcfs, tbi -> [ meta.id, meta, vcfs, tbi ] }
    // BCFtools ROH cannot take .gzi but .tbi
    def af_tbi_keyed = BGZIPTABIX_AF_FILE.out.gz_index
        .join(BGZIPTABIX_AF_FILE.out.tbi)
        .map{ meta, af, _af_gzi, af_tbi -> [ meta.id, af, af_tbi ] }

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

    BCFTOOLS_ROHVIZ ( BCFTOOLS_ROH.out.roh, samplesheet, [], [] )

    emit:
    roh          = BCFTOOLS_ROH.out.roh        // channel: [ meta, roh      ]
    roh_viz      = BCFTOOLS_ROHVIZ.out.output  // channel: [ meta, output   ]
    versions     = ch_versions                 // channel: [ versions.yml   ]

}

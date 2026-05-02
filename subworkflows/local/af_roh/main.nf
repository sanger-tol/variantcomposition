include { BCFTOOLS_QUERY  as BCFTOOLS_QUERY     } from '../../../modules/nf-core/bcftools/query/main'
include { BGZIPTABIX      as BGZIPTABIX_AF_FILE } from '../../../modules/sanger-tol/bgziptabix/main'
include { BCFTOOLS_ROH    as BCFTOOLS_ROH       } from '../../../modules/nf-core/bcftools/roh/main'
include { BCFTOOLS_ROHVIZ as BCFTOOLS_ROHVIZ    } from '../../../modules/nf-core/bcftools/rohviz/main'
include { SPLITROH        as SPLITROH           } from '../../../modules/local/splitroh/main'
include { TABIX_BGZIP     as BGZIP_ROH          } from '../../../modules/nf-core/tabix/bgzip/main'
include { BGZIPTABIX      as BGZIPTABIX_ST      } from '../../../modules/sanger-tol/bgziptabix/main'
include { BGZIPTABIX      as BGZIPTABIX_RG      } from '../../../modules/sanger-tol/bgziptabix/main'

workflow AF_ROH {
    take:
    vcfs_tbi   // channel: [ meta, VCF/gVCF, tbi ]

    main:
    ch_versions = channel.empty()

    //
    // MODULE: Extract allele frequency information from VCF files
    // Uses bcftools query to calculate allele frequencies, which are required for ROH detection
    //
    BCFTOOLS_QUERY ( vcfs_tbi, [], [], [] )

    //
    // MODULE: Compress and index the allele frequency file
    // The maximum sequence length is not available in the pipeline so just pass 0 for now
    //
    BGZIPTABIX_AF_FILE ( BCFTOOLS_QUERY.out.output
        .map { meta, input -> [ meta, input, 0 ]}
    )

    //
    // CHANNEL MANIPULATION: Prepare matched inputs for BCFTOOLS_ROH
    //

    // BCFtools roh requires [VCF + index] and [AF file + index], both correspond to the same sample
    // Strategy: Use meta.id as a key to join VCF and AF channels

    // Key VCF channel by sample ID for joining
    def vcfs_tbi_keyed = vcfs_tbi
        .map { meta, vcfs, tbi -> [ meta.id, meta, vcfs, tbi ] }

    // Key AF channel by sample ID and combine bgzip output with tabix index
    //   bcftools roh requires .tbi index, not .gzi
    def af_tbi_keyed = BGZIPTABIX_AF_FILE.out.gz_index
        .join(BGZIPTABIX_AF_FILE.out.tbi)
        .map{ meta, af, _af_gzi, af_tbi -> [ meta.id, af, af_tbi ] }

    // Join VCF and AF channels on sample ID
    def ch_vcfs_af_joined = vcfs_tbi_keyed
        .join(af_tbi_keyed)


    //
    // MODULE: Detect runs of homozygosity
    //

    BCFTOOLS_ROH(
        ch_vcfs_af_joined.map{ _meta_id, meta, vcfs, vcf_tbi, _af, _af_tbi -> [ meta, vcfs, vcf_tbi] },
        ch_vcfs_af_joined.map{ _meta_id, _meta, _vcfs, _vcf_tbi, af, af_tbi -> [ af, af_tbi] },
        [], // genetic_map
        [], // regions_file
        [], // samples_file
        []  // targets_file
    )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )


    //
    // MODULE: Visualize ROH results as interactive HTML
    //

    BCFTOOLS_ROHVIZ (
        BCFTOOLS_ROH.out.roh,
        vcfs_tbi.map{ meta, vcfs, _vcf_tbi -> [ meta, vcfs ] },
        [], // regions_list
        []  // samples_file
    )


    //
    // MODULE: Split ROH results to two files containing ST and RG regions respectively
    //

    SPLITROH(BCFTOOLS_ROH.out.roh)


    //
    // Compress and index output files
    //

    BGZIP_ROH(BCFTOOLS_ROH.out.roh)

    BGZIPTABIX_RG ( SPLITROH.out.roh_rg
        .map { meta, input -> [ meta, input, 0 ] }   // Max_seq_length set to 0 for now
    )

    BGZIPTABIX_ST ( SPLITROH.out.roh_st
        .map { meta, input -> [ meta, input, 0 ] }   // Max_seq_length set to 0 for now
    )


    emit:
    compressed_roh          = BGZIP_ROH.out.output         // channel: [ meta, output   ]
    compressed_roh_rg_index = BGZIPTABIX_RG.out.gz_index   // channel: [ meta, gz_index ]
    roh_rg_tbi              = BGZIPTABIX_RG.out.tbi        // channel: [ meta, tbi      ]
    compressed_roh_st_index = BGZIPTABIX_ST.out.gz_index   // channel: [ meta, gz_index ]
    roh_st_tbi              = BGZIPTABIX_ST.out.tbi        // channel: [ meta, tbi      ]
    roh_viz                 = BCFTOOLS_ROHVIZ.out.html     // channel: [ meta, html     ]
    versions                = ch_versions                  // channel: [ versions.yml   ]

}

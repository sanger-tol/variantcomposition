include { VCFTOOLS     as VCFTOOLS_SITE_PI          }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_HET              }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_SNP_DENSITY      }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_INDEL_LENGTH     }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_ALLELE_FREQUENCY }   from '../../../modules/nf-core/vcftools/main'
include { BGZIPTABIX   as BGZIPTABIX_PI             }   from '../../../modules/sanger-tol/bgziptabix/main'
include { BGZIPTABIX   as BGZIPTABIX_SD             }   from '../../../modules/sanger-tol/bgziptabix/main'
include { BGZIPTABIX   as BGZIPTABIX_AF             }   from '../../../modules/sanger-tol/bgziptabix/main'


workflow FEATURES {
    take:
    samplesheet        // channel: [ meta, VCF/gVCF ]
    site_pi_positions  // path to positions file to include or exclude

    main:
    ch_versions = channel.empty()

    // Divide input channel into vcf and gvcf branches
    def vcfs = samplesheet
        .branch { meta, _data ->
            vcf  : meta.datatype == "vcf" || meta.datatype == "bcf"
            gvcf : meta.datatype == "gvcf" || meta.datatype == "gbcf"
        }

    //
    // Call VCFtools for VCF analysis
    //

    // Per-site (base) nucleotide diversity (originally in variant-calling pipeline)
    VCFTOOLS_SITE_PI( samplesheet, site_pi_positions, [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SITE_PI.out.versions )

    // SNP density
    //   The default window size is 1 kb
    VCFTOOLS_SNP_DENSITY( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SNP_DENSITY.out.versions )

    // Allele frequency
    VCFTOOLS_ALLELE_FREQUENCY( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_ALLELE_FREQUENCY.out.versions )

    // Heterozygosity (originally in variant-calling pipeline)
    //   This feature only work with VCF files
    VCFTOOLS_HET( vcfs.vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    // InDel length distribution
    VCFTOOLS_INDEL_LENGTH( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_INDEL_LENGTH.out.versions )

    //
    // Compress and index output files that contain chromosomal- and position- based analyses
    //

    BGZIPTABIX_PI ( VCFTOOLS_SITE_PI.out.sites_pi
        .map { meta, input -> [ meta, input, 0 ] },   // Max_seq_length set to 0 for now
        [ [], [], [] ]
    )

    BGZIPTABIX_SD ( VCFTOOLS_SNP_DENSITY.out.snp_density
        .map { meta, input -> [ meta, input, 0 ] },   // Max_seq_length set to 0 for now
        [ [], [], [] ]
    )

    BGZIPTABIX_AF ( VCFTOOLS_ALLELE_FREQUENCY.out.frq
        .map { meta, input -> [ meta, input, 0 ] },   // Max_seq_length set to 0 for now
        [ [], [], [] ]
    )

    emit:
    compressed_sites_pi_index    = BGZIPTABIX_PI.out.gz_index             // channel: [ meta, gz_index       ]
    sites_pi_tbi                 = BGZIPTABIX_PI.out.tbi                  // channel: [ meta, tbi            ]
    compressed_snp_density_index = BGZIPTABIX_SD.out.gz_index             // channel: [ meta, gz_index       ]
    snp_density_tbi              = BGZIPTABIX_SD.out.tbi                  // channel: [ meta, tbi            ]
    compressed_af_index          = BGZIPTABIX_AF.out.gz_index             // channel: [ meta, gz_index       ]
    af_tbi                       = BGZIPTABIX_AF.out.tbi                  // channel: [ meta, tbi            ]
    heterozygosity               = VCFTOOLS_HET.out.heterozygosity        // channel: [ meta, heterozygosity ]
    indel_lengths                = VCFTOOLS_INDEL_LENGTH.out.indel_hist   // channel: [ meta, indel_lengths  ]
    versions                     = ch_versions                            // channel: [ versions.yml         ]

}

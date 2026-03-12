include { VCFTOOLS     as VCFTOOLS_SITE_PI          }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_HET              }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_SNP_DENSITY      }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_INDEL_LENGTH     }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_ALLELE_FREQUENCY }   from '../../../modules/nf-core/vcftools/main'
include { BGZIPTABIX   as BGZIPTABIX                }   from '../../../modules/sanger-tol/bgziptabix/main'
include { TABIX_BGZIP  as BGZIP                     }   from '../../../modules/nf-core/tabix/bgzip/main'
include { TABIX_TABIX  as TABIX_PI                  }   from '../../../modules/nf-core/tabix/tabix/main'

workflow FEATURES {
    take:
    samplesheet        // channel: [ meta, VCF/gVCF ]
    site_pi_positions  // path to positions file to include or exclude

    main:
    ch_versions = channel.empty()

    // Divide input channel into vcf and gvcf branches
    def vcfs = samplesheet
        .branch { meta, _data ->
            vcf  : meta.datatype == "vcf"
            gvcf : meta.datatype == "gvcf"
        }

    // Call VCFtools for per-site (base) nucleotide diversity (originally in variant-calling pipeline)
    VCFTOOLS_SITE_PI( samplesheet, site_pi_positions, [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SITE_PI.out.versions )

    // Call VCFtools to calculate heterozygosity (originally in variant-calling pipeline)
    // This feature work with VCF files, output of gVCF only contains the header
    VCFTOOLS_HET( vcfs.vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    // Call VCFtools for SNP density
    // the default window size is 1 kb
    VCFTOOLS_SNP_DENSITY( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SNP_DENSITY.out.versions )

    // Call VCFtools for InDel length distribution
    VCFTOOLS_INDEL_LENGTH( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_INDEL_LENGTH.out.versions )

    // Call VCFtools for allele frequency
    VCFTOOLS_ALLELE_FREQUENCY( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_ALLELE_FREQUENCY.out.versions )

    // Compress and index AF output files
    //   max_seq_length set to 0 for now
    params.max_seq_length = 0
    BGZIPTABIX ( VCFTOOLS_ALLELE_FREQUENCY.out.frq
        .map { meta, input -> [ meta, input, params.max_seq_length ] }
    )

    // Compress output files
    // current output to compress: pi
    BGZIP ( VCFTOOLS_SITE_PI.out.sites_pi )
    ch_versions = ch_versions.mix ( BGZIP.out.versions.first() )

    // Index the compressed .pi files
    TABIX_PI ( BGZIP.out.output )
    ch_versions = ch_versions.mix ( TABIX_PI.out.versions )

    emit:
    af_and_index        = BGZIPTABIX.out.gz_index              // channel: [ meta, gz_index       ]
    af_tbi              = BGZIPTABIX.out.tbi                   // channel: [ meta, tbi            ]
    compressed_sites_pi = BGZIP.out.output                     // channel: [ meta, output         ]
    sites_pi_tbi        = TABIX_PI.out.tbi                     // channel: [ meta, tbi            ]
    heterozygosity      = VCFTOOLS_HET.out.heterozygosity      // channel: [ meta, heterozygosity ]
    snp_density         = VCFTOOLS_SNP_DENSITY.out.snp_density // channel: [ meta, snp_density    ]
    indel_lengths       = VCFTOOLS_INDEL_LENGTH.out.indel_hist // channel: [ meta, indel_lengths  ]
    versions            = ch_versions                          // channel: [ versions.yml         ]

}

// Features to include in this subworkflow:
//      Calculation of heterozygosity (existing feature in variant-calling pipeline, using vcftools)
//      Per-site nucleotide diversity (existing feature in variant-calling pipeline, using vcftools)
//      Allele frequency
//      SNP-density tracks
//      InDel size distribution
//      Runs of homozygosity

include { VCFTOOLS     as VCFTOOLS_SITE_PI   }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_HET       }   from '../../modules/nf-core/vcftools/main'
include { BCFTOOLS_ROH as BCFTOOLS_ROH       }   from '../../modules/nf-core/bcftools/roh/main'
include { TABIX_TABIX  as TABIX              }   from '../../modules/nf-core/tabix/tabix/main'
include { TABIX_BGZIP  as BGZIP              }   from '../../modules/nf-core/tabix/bgzip/main'

workflow FEATURES {
    take:
    vcf               // [ val(meta), vcf ]
    site_pi_positions // path to positions file to include or exclude

    main:
    ch_versions = Channel.empty()

    // index the input vcf
    ch_tbi = TABIX( vcf ).tbi
    ch_versions = ch_versions.mix( TABIX.out.versions )

    // combine the vcf and tbi channels as the input of BCFtools_ROH
    vcf
        .combine( ch_tbi )
        .map { meta_vcf, vcf_file, meta_tbi, tbi -> [ meta_vcf + meta_tbi, vcf_file, tbi ] }
        .set { ch_vcf_tbi }

    // ch_vcf_tbi.view()

    // place saved for transfer vcf to bcf if needed

    // call vcftools for per site (base) nucleotide diversity
    VCFTOOLS_SITE_PI( vcf, site_pi_positions, [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SITE_PI.out.versions )

    // call vcftools to calculate for heterozygosity
    VCFTOOLS_HET( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    // call bcftools for runs of homozygosity
    BCFTOOLS_ROH( ch_vcf_tbi, [ [], [] ], [], [], [], [] )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )

    // compress output files
    // curent output to compress: pi
    BGZIP ( VCFTOOLS_SITE_PI.out.sites_pi )
    ch_versions = ch_versions.mix ( BGZIP.out.versions.first() )

    emit:
    tbi                 = ch_tbi                           // channel: [ meta, vcf_tbi        ]
    compressed_sites_pi = BGZIP.out.output                 // channel: [ meta, output         ]
    heterozygosity      = VCFTOOLS_HET.out.heterozygosity  // channel: [ meta, heterozygosity ]
    roh                 = BCFTOOLS_ROH.out.roh             // channel: [ meta, roh            ]
    versions            = ch_versions                      // channel: [ versions.yml         ]

}

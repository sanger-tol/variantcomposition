// Features to include in this subworkflow:
//      Calculation of heterozygosity (existing feature in variant-calling pipeline, using vcftools)
//      Per-site nucleotide diversity (existing feature in variant-calling pipeline, using vcftools)
//      Allele frequency
//      SNP-density tracks
//      InDel size distribution
//      Runs of homozygosity

include { VCFTOOLS     as VCFTOOLS_SITE_PI          }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_HET              }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_SNP_DENSITY      }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_ALLELE_FREQUENCY }   from '../../modules/nf-core/vcftools/main'
include { BCFTOOLS_ROH as BCFTOOLS_ROH              }   from '../../modules/nf-core/bcftools/roh/main'
include { TABIX_TABIX  as TABIX                     }   from '../../modules/nf-core/tabix/tabix/main'
include { TABIX_BGZIP  as BGZIP                     }   from '../../modules/nf-core/tabix/bgzip/main'

workflow FEATURES {
    take:
    vcf                // [ val(meta), vcf ]
    site_pi_positions  // path to positions file to include or exclude
    // snp_density_window // size of the window for SNP density calculation

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

    // call VCFtools for per site (base) nucleotide diversity
    VCFTOOLS_SITE_PI( vcf, site_pi_positions, [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SITE_PI.out.versions )

    // call VCFtools to calculate for heterozygosity
    VCFTOOLS_HET( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    // call VCFtools for SNP density
    // need to define a size
    VCFTOOLS_SNP_DENSITY( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SNP_DENSITY.out.versions )

    // call VCFtools for allele frequency
    VCFTOOLS_ALLELE_FREQUENCY( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_ALLELE_FREQUENCY.out.versions )

    // call BCFtools for runs of homozygosity
    BCFTOOLS_ROH( ch_vcf_tbi, [ [], [] ], [], [], [], [] )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )

    // compress output files
    // current output to compress: pi
    BGZIP ( VCFTOOLS_SITE_PI.out.sites_pi )
    ch_versions = ch_versions.mix ( BGZIP.out.versions.first() )

    emit:
    tbi                 = ch_tbi                               // channel: [ meta, vcf_tbi        ]
    compressed_sites_pi = BGZIP.out.output                     // channel: [ meta, output         ]
    heterozygosity      = VCFTOOLS_HET.out.heterozygosity      // channel: [ meta, heterozygosity ]
    snp_density         = VCFTOOLS_SNP_DENSITY.out.snp_density // channel: [ meta, snp_density    ]
    allele_frequency    = VCFTOOLS_ALLELE_FREQUENCY.out.frq    // channel: [ meta, allele_frequency ]
    roh                 = BCFTOOLS_ROH.out.roh                 // channel: [ meta, roh            ]
    versions            = ch_versions                          // channel: [ versions.yml         ]

}

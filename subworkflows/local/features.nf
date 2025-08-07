// Features to include in this subworkflow:
//      Calculation of heterozygosity (existing feature in variant-calling pipeline, using vcftools)
//      Per-site nucleotide diversity (existing feature in variant-calling pipeline, using vcftools)
//      Allele frequency
//      SNP-density tracks
//      InDel size distribution
//      Runs of homozygosity

include { VCFTOOLS    as VCFTOOLS_SITE_PI   }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS    as VCFTOOLS_HET       }   from '../../modules/nf-core/vcftools/main'
include { TABIX_BGZIP as BGZIP              }   from '../../modules/nf-core/tabix/bgzip/main'

workflow FEATURES {
    take:
    vcf               // [ val(meta), vcf ]
    site_pi_positions // path to positions file to include or exclude

    main:
    ch_versions = Channel.empty()

    // place saved for indexing input vcf if needed



    // call vcftools for per site (base) nucleotide diversity
    VCFTOOLS_SITE_PI( vcf, site_pi_positions, [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SITE_PI.out.versions )

    // call vcftools to calculate for heterozygosity
    VCFTOOLS_HET( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    // compress output files
    // curent output to compress: pi
    BGZIP ( VCFTOOLS_SITE_PI.out.sites_pi )
    ch_versions = ch_versions.mix ( BGZIP.out.versions.first() )


    emit:
    compressed_sites_pi = BGZIP.out.output                 // channel: [ meta, output         ]
    heterozygosity      = VCFTOOLS_HET.out.heterozygosity  // channel: [ meta, heterozygosity ]
    versions            = ch_versions                      // channel: [ versions.yml         ]

}

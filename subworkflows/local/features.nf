// Features to include in this subworkflow: 
//      Calculation of heterozygosity (existing feature in variant-calling pipeline, using vcftools)
//      Per-site nucleotide diversity (existing feature in variant-calling pipeline, using vcftools)
//      Allele frequency
//      SNP-density tracks
//      InDel size distribution
//      Runs of homozygosity

include { VCFTOOLS as VCFTOOLS_SITE_PI   }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS as VCFTOOLS_HET       }   from '../../modules/nf-core/vcftools/main'

workflow FEATURES {
    take:
    vcf               // [ val(meta), vcf ]
    site_pi_positions // path to positions file to include or exclude

    main:
    ch_versions = Channel.empty()

    // call vcftools for per site (base) nucleotide diversity
    VCFTOOLS_SITE_PI(
      vcf, site_pi_positions, []
    )
    ch_versions = ch_versions.mix( VCFTOOLS_SITE_PI.out.versions )

    // call vcftools to calculate for heterozygosity
    VCFTOOLS_HET(
      vcf, [], []
    )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    emit:
    stite_pi       = VCFTOOLS_SITE_PI.out.sites_pi    // channel: [ meta, site_pi         ]
    heterozygosity = VCFTOOLS_HET.out.heterozygosity  // channel: [ meta,  heterozygosity ]
    versions       = ch_versions                      // channel: [ versions.yml          ]

}
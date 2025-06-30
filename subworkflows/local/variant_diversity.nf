// Features to include in this subworkflow: 
//      SNP-density tracks
//      Per-site nucleotide diversity (existing feature in variant-calling pipeline, using vcftools)
//      InDel size distribution


//
// Call vcftools to process VCF files
//

include { VCFTOOLS as VCFTOOLS_SITE_PI   }   from '../../modules/nf-core/vcftools/main'

workflow PROCESS_VCF {
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

    emit:
    versions       = ch_versions                      // channel: [ versions.yml ]
    stite_pi       = VCFTOOLS_SITE_PI.out.sites_pi    // [ meta, site_pi ]

}
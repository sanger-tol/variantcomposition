include { VCFTOOLS     as VCFTOOLS_SITE_PI          }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_HET              }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_SNP_DENSITY      }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_ALLELE_FREQUENCY }   from '../../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_INDEL_LENGTH     }   from '../../../modules/nf-core/vcftools/main'
include { BCFTOOLS_ROH as BCFTOOLS_ROH              }   from '../../../modules/nf-core/bcftools/roh/main'
include { TABIX_BGZIP  as BGZIP                     }   from '../../../modules/nf-core/tabix/bgzip/main'

workflow FEATURES {
    take:
    samplesheet        // channel: [ meta, VCF/gVCF ]
    vcfs_tbi           // channel: [ meta, VCF/gVCF, tbi ]
    site_pi_positions  // path to positions file to include or exclude

    main:
    ch_versions = Channel.empty()

    // Divide input channel into vcf and gvcf branches
    samplesheet
        .branch { meta, data ->
            vcf  : meta.datatype == "vcf"
            gvcf : meta.datatype == "gvcf"
        }
        .set { vcfs }

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

    // Call VCFtools for allele frequency
    VCFTOOLS_ALLELE_FREQUENCY( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_ALLELE_FREQUENCY.out.versions )

    // Call VCFtools for InDel length distribution
    VCFTOOLS_INDEL_LENGTH( samplesheet, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_INDEL_LENGTH.out.versions )

    // Call BCFtools for ROH
    BCFTOOLS_ROH( vcfs_tbi, [ [], [] ], [], [], [], [] )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )

    // Compress output files
    // current output to compress: pi
    BGZIP ( VCFTOOLS_SITE_PI.out.sites_pi )
    ch_versions = ch_versions.mix ( BGZIP.out.versions.first() )

    emit:
    compressed_sites_pi = BGZIP.out.output                     // channel: [ meta, output           ]
    heterozygosity      = VCFTOOLS_HET.out.heterozygosity      // channel: [ meta, heterozygosity   ]
    snp_density         = VCFTOOLS_SNP_DENSITY.out.snp_density // channel: [ meta, snp_density      ]
    allele_frequency    = VCFTOOLS_ALLELE_FREQUENCY.out.frq    // channel: [ meta, allele_frequency ]
    indel_lengths       = VCFTOOLS_INDEL_LENGTH.out.indel_hist // channel: [ meta, indel_lengths    ]
    roh                 = BCFTOOLS_ROH.out.roh                 // channel: [ meta, roh              ]
    versions            = ch_versions                          // channel: [ versions.yml           ]

}


//      InDel size distribution
//      Runs of homozygosity

include { VCFTOOLS     as VCFTOOLS_SITE_PI          }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_HET              }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_SNP_DENSITY      }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_ALLELE_FREQUENCY }   from '../../modules/nf-core/vcftools/main'
include { VCFTOOLS     as VCFTOOLS_INDEL_LENGTH     }   from '../../modules/nf-core/vcftools/main'
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

    // Index the input VCF
    ch_tbi = TABIX( vcf ).tbi
    ch_versions = ch_versions.mix( TABIX.out.versions )

    // Combine the VCF and TBI channels as the input of BCFtools_ROH
    // vcf
    //     .join( ch_tbi )
    //     .map { meta_vcf, vcf_file, meta_tbi, tbi -> [ meta_vcf + meta_tbi, vcf_file, tbi ] }
    //     .set { ch_vcf_tbi }

    // Key VCF files by filename (without .tbi)
    vcf_keyed = vcf.map { meta, file -> tuple(file.simpleName, meta, file) }

    // Key TBI files by filename (without .tbi)
    tbi_keyed = ch_tbi.map { meta, file ->
        def baseName = file.simpleName.replaceFirst(/\.tbi$/, '')
        tuple(baseName, meta, file)
    }

    // Join matching pairs
    vcf_keyed
        .join(tbi_keyed)
        .map { id, meta_vcf, vcf_file, meta_tbi, tbi_file ->
        [ meta_vcf + meta_tbi, vcf_file, tbi_file ]
        }
        .set { ch_vcf_tbi }

    ch_vcf_tbi.view()

    // Place saved for transfer VCF to BCF if needed

    // Call VCFtools for per-site (base) nucleotide diversity (originally in variant-calling pipeline)
    VCFTOOLS_SITE_PI( vcf, site_pi_positions, [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SITE_PI.out.versions )

    // Call VCFtools to calculate heterozygosity (originally in variant-calling pipeline)
    VCFTOOLS_HET( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    // Call VCFtools for SNP density
    // need to define a window size, currently using 1000
    VCFTOOLS_SNP_DENSITY( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_SNP_DENSITY.out.versions )

    // Call VCFtools for allele frequency
    VCFTOOLS_ALLELE_FREQUENCY( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_ALLELE_FREQUENCY.out.versions )

    // Call VCFtools for InDel length distribution
    VCFTOOLS_INDEL_LENGTH( vcf, [], [] )
    ch_versions = ch_versions.mix( VCFTOOLS_INDEL_LENGTH.out.versions )

    // Call BCFtools for runs of homozygosity
    BCFTOOLS_ROH( ch_vcf_tbi, [ [], [] ], [], [], [], [] )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )

    // Compress output files
    // current output to compress: pi
    BGZIP ( VCFTOOLS_SITE_PI.out.sites_pi )
    ch_versions = ch_versions.mix ( BGZIP.out.versions.first() )

    emit:
    tbi                 = ch_tbi                               // channel: [ meta, vcf_tbi          ]
    compressed_sites_pi = BGZIP.out.output                     // channel: [ meta, output           ]
    heterozygosity      = VCFTOOLS_HET.out.heterozygosity      // channel: [ meta, heterozygosity   ]
    snp_density         = VCFTOOLS_SNP_DENSITY.out.snp_density // channel: [ meta, snp_density      ]
    allele_frequency    = VCFTOOLS_ALLELE_FREQUENCY.out.frq    // channel: [ meta, allele_frequency ]
    indel_lengths       = VCFTOOLS_INDEL_LENGTH.out.indel_hist // channel: [ meta, indel_lengths   ]
    roh                 = BCFTOOLS_ROH.out.roh                 // channel: [ meta, roh              ]
    versions            = ch_versions                          // channel: [ versions.yml           ]

}

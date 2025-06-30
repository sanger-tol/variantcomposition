// Features to include in this subworkflow: 
//      Calculation of heterozygosity (existing feature in variant-calling pipeline, using vcftools)
//      Runs of homozygosity

//
// Call vcftools to process VCF files
//

include { VCFTOOLS as VCFTOOLS_HET       }   from '../../modules/nf-core/vcftools/main'

workflow PROCESS_VCF {
    take:
    vcf               // [ val(meta), vcf ]

    main:
    ch_versions = Channel.empty()

    // call vcftools to calculate for heterozygosity
    VCFTOOLS_HET(
      vcf, [], []
    )
    ch_versions = ch_versions.mix( VCFTOOLS_HET.out.versions )

    emit:
    versions       = ch_versions                      // channel: [ versions.yml ]
    heterozygosity = VCFTOOLS_HET.out.heterozygosity  // [ meta,  heterozygosity ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_variantcomposition_pipeline'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//

include { FEATURES             } from '../subworkflows/local/features'
include { BCFTOOLS_STATS_PLOT  } from '../subworkflows/local/bcftools_stats_plot'
include { TABIX_TABIX as TABIX } from '../modules/nf-core/tabix/tabix/main'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow VARIANTCOMPOSITION {

    take:
    ch_samplesheet          // channel: samplesheet read in from --input
    ch_positions            // channel: positions file to include or exclude

    main:
    // Initialize an empty versions channel
    ch_versions = Channel.empty()

    // Index the input VCF
    ch_tbi = TABIX( ch_samplesheet ).tbi
    ch_versions = ch_versions.mix( TABIX.out.versions )

    // Combine the VCF and TBI channels
    ch_samplesheet
        .join( ch_tbi )
        .set { ch_vcfs_tbi }

    //
    // SUBWORKFLOW: FEATURES
    //

    FEATURES (
        ch_samplesheet,
        ch_vcfs_tbi,
        ch_positions
    )
    ch_versions = ch_versions.mix( FEATURES.out.versions )

    //
    // SUBWORKFLOW: BCFTOOLS_STATS_PLOT
    //

    BCFTOOLS_STATS_PLOT (
        ch_vcfs_tbi
    )
    ch_versions = ch_versions.mix( BCFTOOLS_STATS_PLOT.out.versions )


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'variantcomposition_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

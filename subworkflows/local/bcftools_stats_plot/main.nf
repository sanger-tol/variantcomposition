include { BCFTOOLS_STATS        as BCFTOOLS_STATS }   from '../../../modules/nf-core/bcftools/stats/main'
include { BCFTOOLS_PLOTVCFSTATS as PLOTVCFSTATS   }   from '../../../modules/local/plotvcfstats/main'
include { PIGZ_COMPRESS         as PIGZ           }   from '../../../modules/nf-core/pigz/compress/main'
include { TAR                   as TAR            }   from '../../../modules/nf-core/tar/main'

workflow BCFTOOLS_STATS_PLOT {
    take:
    vcf_tbi

    main:
    ch_versions = Channel.empty()

    // Call BCFtools stats for general QC
    BCFTOOLS_STATS( vcf_tbi, [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ] )
    ch_versions = ch_versions.mix( BCFTOOLS_STATS.out.versions )

    PIGZ( BCFTOOLS_STATS.out.stats )
    ch_versions = ch_versions.mix( PIGZ.out.versions )

    // Plot BCFtools stats in a PDF
    PLOTVCFSTATS( BCFTOOLS_STATS.out.stats )
    ch_versions = ch_versions.mix( PLOTVCFSTATS.out.versions )

    // Compress plot-stats raw data folder
    TAR ( PLOTVCFSTATS.out.plot_dir, '.gz' )
    ch_versions = ch_versions.mix ( TAR.out.versions )

    emit:
    stats               = BCFTOOLS_STATS.out.stats    // channel: [ meta, stats    ]
    compressed_stats    = PIGZ.out.archive            // channel: [ meta, archive  ]
    plot_pdf            = PLOTVCFSTATS.out.plot_pdf   // channel: [ meta, plot_pdf ]
    plot_dir            = PLOTVCFSTATS.out.plot_dir   // channel: [ meta, plot_dir ]
    compressed_plot_dir = TAR.out.archive             // channel: [ meta, archive  ]
    versions            = ch_versions                 // channel: [ versions.yml   ]

}

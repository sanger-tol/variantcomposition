include { BCFTOOLS_QUERY  as BCFTOOLS_QUERY     } from '../../../modules/nf-core/bcftools/query/main'
include { BGZIPTABIX      as BGZIPTABIX_AF_FILE } from '../../../modules/sanger-tol/bgziptabix/main'
include { BCFTOOLS_ROH    as BCFTOOLS_ROH       } from '../../../modules/nf-core/bcftools/roh/main'
include { BCFTOOLS_ROHVIZ as BCFTOOLS_ROHVIZ    } from '../../../modules/nf-core/bcftools/rohviz/main'
include { GAWK            as GAWK_SPLIT_RG      } from '../../../modules/nf-core/gawk/main'
include { GAWK            as GAWK_SPLIT_ST      } from '../../../modules/nf-core/gawk/main'
include { BGZIPTABIX      as BGZIPTABIX_ST      } from '../../../modules/sanger-tol/bgziptabix/main'
include { BGZIPTABIX      as BGZIPTABIX_RG      } from '../../../modules/sanger-tol/bgziptabix/main'

workflow AF_ROH {
    take:
    vcfs_tbi   // channel: [ meta, VCF/gVCF, tbi ]
    af_file    // channel: [ meta, AF file ]

    main:
    ch_versions = channel.empty()

    //
    // MODULE: Extract sample names to identify multi-sample VCFs
    //
    BCFTOOLS_QUERY ( vcfs_tbi, [], [], [] )

    // Join output and input, read the text file to count the number of sample,
    def ch_vcfs_multi_sample_info = BCFTOOLS_QUERY.out.output
        .join( vcfs_tbi )
        .map { meta, txt, vcfs, tbi -> [ meta + [multi_sample: file(txt).readLines().size > 1], vcfs, tbi ] }

    //
    // MODULE: Compress and index the allele frequency file
    // The maximum sequence length is not available in the pipeline so just pass 0 for now
    //
    BGZIPTABIX_AF_FILE ( af_file
        .map { meta, input -> [ meta, input, 0 ]},
        [ [], [], [] ]
    )

    //
    // CHANNEL MANIPULATION: Prepare matched inputs for BCFTOOLS_ROH
    //

    // BCFtools roh requires [VCF + index] and [AF file + index] to correspond to the same sample
    // Strategy: Use meta.id as a key to join VCF and AF channels

    // Key VCF channel by sample ID for joining
    def vcfs_tbi_keyed = ch_vcfs_multi_sample_info
        .map { meta, vcfs, tbi -> [ meta.id, meta, vcfs, tbi ] }

    // Key AF channel by sample ID and combine bgzip output with tabix index
    //   bcftools roh requires .tbi index, not .gzi
    def af_tbi_keyed = BGZIPTABIX_AF_FILE.out.gz_index
        .join(BGZIPTABIX_AF_FILE.out.tbi)
        .map{ meta, af, _af_gzi, af_tbi -> [ meta.id, af, af_tbi ] }

    // Let's compare both
    def ch = vcfs_tbi_keyed
        .join(af_tbi_keyed, remainder: true)
        .branch {
            no_vcf:  it[1] == null
            no_af:   it[4] == null
            matched: true
        }

    // AF file with no VCF: raise an error
    ch.no_vcf.map { id, _null, af, af_tbi ->
        error("${id} AF file (${af.baseName}) has not matching variant file")
    }

    // VCF files with no matching AF file. Pad with [] to fit BCFTOOLS_ROH
    ch_vcfs_no_af_file = ch.no_af
         .map { id, meta, vcfs, tbi, _null -> [id, meta, vcfs, tbi, [], []] }

    // All VCF inputs for BCFTOOLS_ROH
    def ch_vcfs_af_joined = ch.matched
        .mix( ch_vcfs_no_af_file )


    //
    // MODULE: Detect runs of homozygosity
    //

    BCFTOOLS_ROH(
        ch_vcfs_af_joined.map{ _meta_id, meta, vcfs, vcf_tbi, _af, _af_tbi -> [ meta, vcfs, vcf_tbi] },
        ch_vcfs_af_joined.map{ _meta_id, _meta, _vcfs, _vcf_tbi, af, af_tbi -> [ af, af_tbi] },
        [], // genetic_map
        [], // regions_file
        [], // samples_file
        []  // targets_file
    )
    ch_versions = ch_versions.mix( BCFTOOLS_ROH.out.versions )


    //
    // MODULE: Visualize ROH results as interactive HTML
    //

    ch_vcfs_roh = ch_vcfs_af_joined
        .map { _meta_id, meta, vcf, _vcf_tbi, _af, _af_tbi -> [ meta, vcf ] }
        .join( BCFTOOLS_ROH.out.roh )

    BCFTOOLS_ROHVIZ (
        ch_vcfs_roh.map { meta, _vcf, roh -> [meta, roh] },
        ch_vcfs_roh.map { meta, vcf, _roh -> [meta, vcf] },
        [], // regions_list
        []  // samples_file
    )


    //
    // MODULE: Split ROH results to two files containing ST and RG regions respectively
    //         Do it by sample if the VCF has multiple samples
    //

    // Channel 2: select the split_sample_??.awk script for multi-sample VCFs, split_all_??.awk otherwise
    // Channel 3: the former creates its own files, while the latter prints to stdout

    GAWK_SPLIT_RG(
        BCFTOOLS_ROH.out.roh,
        BCFTOOLS_ROH.out.roh.map { meta, _roh -> file("$projectDir/assets/split_${meta.multi_sample ? "sample" : "all"}_rg.awk", checkIfExists: true) },
        BCFTOOLS_ROH.out.roh.map{ meta, _roh -> meta.multi_sample },
    )

    GAWK_SPLIT_ST(
        BCFTOOLS_ROH.out.roh,
        BCFTOOLS_ROH.out.roh.map { meta, _roh -> file("$projectDir/assets/split_${meta.multi_sample ? "sample" : "all"}_st.awk", checkIfExists: true) },
        BCFTOOLS_ROH.out.roh.map{ meta, _roh -> meta.multi_sample },
    )


    //
    // Compress and index output files
    //

    // GAWK sends either 1 file, or 1 list of files. When a list, flatten it and add the sample name (which is the file base name) to the id

    ch_rg_files = GAWK_SPLIT_RG.out.output
        .flatMap { meta, rg_files -> (rg_files instanceof List ? rg_files.collect { rg -> tuple(meta + [id: "${meta.id}.${rg.baseName}" ], rg) } : [tuple(meta, rg_files)]) }

    BGZIPTABIX_RG ( ch_rg_files
        .map { meta, input -> [ meta, input, 0 ] },   // Max_seq_length set to 0 for now
        [ [], [], 'roh.rg' ]
    )

    ch_st_files = GAWK_SPLIT_ST.out.output
        .flatMap { meta, st_files -> (st_files instanceof List ? st_files.collect { rg -> tuple(meta + [id: "${meta.id}.${rg.baseName}" ], rg) } : [tuple(meta, st_files)]) }

    BGZIPTABIX_ST ( ch_st_files
        .map { meta, input -> [ meta, input, 0 ] },   // Max_seq_length set to 0 for now
        [ [], [], 'roh.st' ]
    )


    emit:
    compressed_roh_rg_index = BGZIPTABIX_RG.out.gz_index   // channel: [ meta, gz_index ]
    roh_rg_tbi              = BGZIPTABIX_RG.out.tbi        // channel: [ meta, tbi      ]
    roh_rg_csi              = BGZIPTABIX_RG.out.csi        // channel: [ meta, csi      ]
    compressed_roh_st_index = BGZIPTABIX_ST.out.gz_index   // channel: [ meta, gz_index ]
    roh_st_tbi              = BGZIPTABIX_ST.out.tbi        // channel: [ meta, tbi      ]
    roh_st_csi              = BGZIPTABIX_ST.out.csi        // channel: [ meta, csi      ]
    roh_viz                 = BCFTOOLS_ROHVIZ.out.html     // channel: [ meta, html     ]
    versions                = ch_versions                  // channel: [ versions.yml   ]

}

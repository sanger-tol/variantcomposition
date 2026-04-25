process SPLITROH {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/a1/a125c778baf3865331101a104b60d249ee15fe1dca13bdafd888926cc5490a34/data':
        'community.wave.seqera.io/library/gawk:5.3.1--e09efb5dfc4b8156' }"

    input:
    tuple val(meta), path(roh)

    output:
    tuple val(meta), path("*.roh.rg"), emit: roh_rg
    tuple val(meta), path("*.roh.st"), emit: roh_st
    tuple val("${task.process}"), val('gawk'), eval("gawk --version | sed '1!d; s/^.*gawk //'"), topic: versions, emit: versions_gawk

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    { grep '^#' "$roh" | grep -v '^# ST'; grep '^RG\t' "$roh"; } > ${prefix}.roh.rg
    { grep '^#' "$roh" | grep -v '^# RG'; grep '^ST\t' "$roh"; } > ${prefix}.roh.st
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.roh.rg
    touch ${prefix}.roh.st
    """
}


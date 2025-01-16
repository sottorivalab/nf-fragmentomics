process FILTERBAMBYSIZE {
    tag "$meta.sampleid"
    label "heavy_process"

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"
    
    input:
    // meta [ caseid, sampleid, timepoint ]
    tuple val(meta), path(bam), path(bai)

    output:
    // meta [ caseid, sampleid, timepoint ]
    tuple val(meta), path("*filtered.bam"), path("*filtered.bam.bai"), emit: filtered
    path "versions.yml"                                              , emit: versions

    when:
    task.ext.when == null || task.ext.when
    
    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    samtools view -h \\
        ${bam} | \\
        awk 'function abs(v) { return v < 0 ? -v : v} \\
        { if (\$0 ~ /^@/) {print} \\
        else { if ( abs(\$9) > ${params.filter_min} && abs(\$9) <= ${params.filter_max} ) {print}}}' | \\
        samtools view -b $args > ${prefix}.filtered.bam
        samtools index ${prefix}.filtered.bam
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${prefix}.filtered.bam
    touch ${prefix}.filtered.bam.bai

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
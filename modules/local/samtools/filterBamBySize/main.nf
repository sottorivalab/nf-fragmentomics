process FILTERBAMBYSIZE {
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"
        
    label "heavy_process"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*filtered.bam"), path("*filtered.bam.bai"), emit: filtered

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    samtools view -h \\
        ${bam} | \\
        awk 'function abs(v) { return v < 0 ? -v : v} \\
        { if (\$0 ~ /^@/) {print} \\
        else { if ( abs(\$9) > ${params.filter_min} && abs(\$9) <= ${params.filter_max} ) {print}}}' | \\
        samtools view -b > ${prefix}.filtered.bam
        samtools index ${prefix}.filtered.bam
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${prefix}.filtered.bam
    touch ${prefix}.filtered.bam.bai
    """
}
process FILTERBAMBYSIZE {
    tag "${meta.sampleid}"
    
    label "heavy_process"

    input:
    tuple val(meta), path(bam), path(bai), path(seg)

    output:
    tuple val(meta), path("*filtered.bam"), path("*filtered.bam.bai"), path(seg), emit: filtered

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    module load samtools
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
process SAMTOOLSFILTERSEG {
    label "heavy_process"

    input:
    tuple val(meta), path(bam), path(bai), path(bed)

    output:
    tuple val(meta), path("*.bam"), emit: ploidy_bam

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bed.baseName}"
    """
    module load samtools
    samtools view -O bam -o ${prefix}.bam -L ${bed} ${bam}
    """

    stub:
    def prefix = task.ext.prefix ?: "${bed.baseName}"
	"""
	touch ${prefix}.bam
	"""
}
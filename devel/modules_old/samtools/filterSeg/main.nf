process SAMTOOLSFILTERSEG {
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"
        
    label "heavy_process"

    input:
    tuple val(meta), path(bam), path(bai), path(bed)

    output:
    tuple val(meta), path("*.bam"), emit: ploidy_bam

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bed.baseName}"
    """
    samtools view -O bam -o ${prefix}.bam -L ${bed} ${bam}
    """

    stub:
    def prefix = task.ext.prefix ?: "${bed.baseName}"
	"""
	touch ${prefix}.bam
	"""
}
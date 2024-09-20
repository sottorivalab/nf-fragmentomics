process SAMTOOLS_COUNTREADS {
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    label "normal_process"

    input:
    tuple val(meta_sample), val(meta_ploidy), path(bam), path(bai)

    output:
    tuple val(meta_sample), val(meta_ploidy), path(bam), path(bai), path("${bam.baseName}_count.txt"), emit: bamcount

    script:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    samtools view -c ${bam} > ${bam.baseName}_count.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${bam.baseName}_count.txt
    """

}
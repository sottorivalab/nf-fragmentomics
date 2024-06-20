process SAMTOOLS_COUNTREADS {
    
    label "normal_process"

    input:
    tuple val(meta_sample), val(meta_ploidy), path(bam), path(bai)

    output:
    tuple val(meta_sample), val(meta_ploidy), path(bam), path(bai), path("${bam.baseName}_count.txt"), emit: bamcount

    script:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    module load samtools
    samtools view -c ${bam} > ${bam.baseName}_count.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${bam.baseName}_count.txt
    """

}
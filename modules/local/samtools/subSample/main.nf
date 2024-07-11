process SAMTOOLS_SUBSAMPLE {

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    label "heavy_process"
    
    input:
    tuple val(meta), path(gainbam), path(neutbam), path(lossbam), path(table)

    output:
    tuple val(meta), path("${gainbam.baseName}.subsample.bam"), path("${neutbam.baseName}.subsample.bam"), path("${lossbam.baseName}.subsample.bam"), emit: subsample_bam

    script:
    """
    fragmentomics_subSample.py --cpu ${task.cpus} ${neutbam} ${gainbam} ${lossbam} ${table}
    """

    stub:
    """
    touch ${neutbam.baseName}.subsample.bam
    touch ${gainbam.baseName}.subsample.bam
    touch ${lossbam.baseName}.subsample.bam
    """
}
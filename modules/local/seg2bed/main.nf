process SEG2BED {
    
    conda "conda-forge::python=3.8.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'biocontainers/python:3.8.3' }"
        
    label "local_executor"
    
    input:
    tuple val(meta), path(bam), path(bai), path(seg), path(freq)

    output:
    tuple val(meta), path(bam), path(bai), path("${meta.sampleid}_GAIN.bed"), path("${meta.sampleid}_NEUT.bed"), path("${meta.sampleid}_LOSS.bed"), emit: ploidy

    script:
    def args = task.ext.args ?: ''
    """
    fragmentomics_seg2bed.py $seg $args
    """

    stub:
    """
    touch ${meta.sampleid}_LOSS.bed
    touch ${meta.sampleid}_NEUT.bed
    touch ${meta.sampleid}_GAIN.bed
    """
}
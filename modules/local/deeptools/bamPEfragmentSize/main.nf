process BAMPEFRAGMENTSIZE {
   
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0':
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

    publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/reports/", 
        mode:'copy', 
        overwrite:true

    label 'fast_process'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*_fragmentsize.png"), path("*_fragmentsize.txt"), emit: bamqc

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    bamPEFragmentSize \\
        -b ${bam} \\
        -hist ${prefix}_fragmentsize.png \\
        -T "Sample: ${meta.sampleid}" \\
        --numberOfProcessors ${task.cpus} \\
        $args 1>${prefix}_fragmentsize.txt
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${prefix}_fragmentsize.png
    touch ${prefix}_fragmentsize.txt
    """
}
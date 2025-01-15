process PLOTCOVERAGE {
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0':
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

    publishDir "${params.outdir}/${meta.caseid}/${meta.sampleid}/fragmentomics/reports/", 
        mode:'copy', 
        overwrite:true

    label 'fast_process'

    input:
    tuple val(meta), path(bam), path(bai), path(seg)

    output:
    tuple val(meta), path("*_coverage.png"), path("*_coverage.tab"),emit: bamcoverage

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    plotCoverage \\
        -b ${bam} \\
        -o ${prefix}_coverage.png \\
        --outRawCounts ${prefix}_coverage.tab \\
        --plotTitle "Sample: ${meta.sampleid}" \\
        --numberOfProcessors ${task.cpus} \\
        $args
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${prefix}_coverage.png
    touch ${prefix}_coverage.tab
    """
}
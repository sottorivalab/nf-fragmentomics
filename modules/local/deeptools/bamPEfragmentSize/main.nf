/*
 * This Nextflow script is part of the nf-fragmentomics project and is located in the deeptools/bamPEfragmentSize module.
 * The script is designed to calculate the fragment size distribution of paired-end BAM files using the bamPEFragmentSize tool from deepTools.
 * It takes paired-end BAM files as input and generates a plot showing the fragment size distribution.
 * The output can be used to assess the quality of the sequencing library and to identify any potential issues with the fragment size distribution.
 */

process BAMPEFRAGMENTSIZE {
    tag "$meta.sampleid"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0':
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

    input:
    // meta: [ caseid, sampleid, timepoint ]
    tuple val(meta), path(bam), path(bai)

    output:
    // meta: [ caseid, sampleid, timepoint ]
    tuple val(meta), path("*_fragmentsize.png"), path("*_fragmentsize.txt"), emit: bamqc
    path "versions.yml"                                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when
    
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
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    deeptools: \$(bamPEFragmentSize --version | sed -e "s/bamPEFragmentSize //g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${prefix}_fragmentsize.png
    touch ${prefix}_fragmentsize.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    deeptools: \$(bamPEFragmentSize --version | sed -e "s/bamPEFragmentSize //g")
    END_VERSIONS
    """
}
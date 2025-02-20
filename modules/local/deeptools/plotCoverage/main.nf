/*
 * PLOTCOVERAGE
 *
 * This process generates coverage plots for sequencing data.
 * It takes as input a BAM file and produces a graphical representation of the coverage across the genome.
 * The output includes a PNG image showing the coverage plot and a tab-delimited text file with the coverage values.
 */
process PLOTCOVERAGE {
    tag "$meta.sampleid"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0 ' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

    input:
    // meta [ caseid, sampleid, timepoint ]
    tuple val(meta), path(bam), path(bai)

    output:
    // meta [ caseid, sampleid, timepoint ]
    tuple val(meta), path("*_coverage.png"), path("*_coverage.tab"), emit: bamcoverage
    path "versions.yml"                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$( plotCoverage --version | sed -e 's/plotCoverage //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${bam.baseName}"
    """
    touch ${prefix}_coverage.png
    touch ${prefix}_coverage.tab

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$( plotCoverage --version | sed -e 's/plotCoverage //g' )
    END_VERSIONS
    """
}
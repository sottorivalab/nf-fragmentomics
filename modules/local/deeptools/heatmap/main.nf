/*
 * This process computes a heatmap iamge from the given input data.
 */
process HEATMAP {
    tag "$meta_sample.sampleid"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0 ' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"

    input:
    tuple val(meta_sample), val(source), path(matrix)

    output:
    tuple val(meta_sample), val(source), path("*_heatmap.png"), emit: heatmap
    path "versions.yml"                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    for MAT in ${matrix.join(' ')}; do
        BASENAME=\$(basename \${MAT} _matrix.gz)
        OUTPUT_FILE=\${BASENAME}_heatmap.png
        plotHeatmap \\
            -m \${MAT} \\
            -o \${OUTPUT_FILE} \\
            --dpi 200 \\
            $args \\
            --plotTitle "${meta_sample.sampleid} over \${BASENAME}"
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$( plotHeatmap --version | sed -e 's/plotHeatmap //g' )
    END_VERSIONS
    """

    stub:
    """
    for MAT in ${matrix.join(' ')}; do
        BASENAME=\$(basename \${MAT} _matrix.gz)
        OUTPUT_FILE=\${BASENAME}_heatmap.png
        touch \${OUTPUT_FILE}
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deeptools: \$( plotHeatmap --version | sed -e 's/plotHeatmap //g' )
    END_VERSIONS
    """
}
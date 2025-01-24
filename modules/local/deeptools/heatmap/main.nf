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
    // meta_sample [caseid, sampleid, timepoint], meta_target [source, name], matrix
    tuple val(meta_sample), val(meta_target), path(matrix)

    output:
    // meta_sample [caseid, sampleid, timepoint], meta_target [source, name], png
	tuple val(meta_sample), val(meta_target), path("*_heatmap.png"), emit: heatmap
    path "versions.yml"                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: matrix.baseName
    """
    plotHeatmap \\
        -m ${matrix} \\
        -o ${prefix}_heatmap.png \\
        --dpi 200 \\
        --plotTitle "Sample: ${meta_sample.sampleid} - Target: ${meta_target.name}" \\
        $args
    
cat <<-END_VERSIONS > versions.yml
"${task.process}":
deeptools: \$(plotHeatmap --version | sed -e "s/plotHeatmap //g")
END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: matrix.baseName
    """
    touch ${prefix}_heatmap.png

cat <<-END_VERSIONS > versions.yml
"${task.process}":
deeptools: \$(plotHeatmap --version | sed -e "s/plotHeatmap //g")
END_VERSIONS
    """
}
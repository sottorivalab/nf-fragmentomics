process HEATMAP {
    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/deeptools:3.5.5--pyhdfd78af_0 ' :
        'biocontainers/deeptools:3.5.5--pyhdfd78af_0' }"
    
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.sampleid}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", 
        mode:'copy', 
        overwrite:true	
    
    label 'fast_process'

    input:
    tuple val(meta_sample), val(meta_target), path(matrix)

    output:
	tuple val(meta_sample), val(meta_target), path("*_heatmap.png"), emit: heatmap

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: matrix.baseName
    """
    plotHeatmap \\
        -m ${matrix} \\
        -o ${prefix}_heatmap.png \\
        --dpi 200 \\
        --plotTitle "Sample: ${meta_sample.id} - Target: ${meta_target.name}" \\
        $args
    """

    stub:
    def prefix = task.ext.prefix ?: matrix.baseName
    """
    touch ${prefix}_heatmap.png
    """
}
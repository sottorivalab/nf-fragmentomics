process HEATMAP {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true	
    label 'hpc_executor'

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
        time = '30m'
	}

    input:
    tuple val(meta_sample), val(meta_target), path(matrix)

    output:
	tuple val(meta_sample), val(meta_target), path("*_heatmap.png"), emit: heatmap

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: matrix.baseName
    def ploidy = matrix.baseName.replace("_matrix","").replaceFirst(/^.*_/,"")
    """
    plotHeatmap \\
        -m ${matrix} \\
        -o ${prefix}_heatmap.png \\
        --dpi 200 \\
        --plotTitle "Sample: ${meta_sample.id} - Target: ${meta_target.name} type: ${ploidy}" \\
        $args
    """

    stub:
    def prefix = task.ext.prefix ?: matrix.baseName
    """
    touch ${prefix}_heatmap.png
    """
}
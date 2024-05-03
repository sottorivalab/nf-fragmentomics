process HEATMAP {
    conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true	

    if ( "${workflow.stubRun}" == "false" ) {
		cpus = 1
		memory = 4.GB
        time = '4h'
	}

    input:
    tuple val(meta_sample), val(meta_target), path(matrix_all), path(matrix_gain), path(matrix_neut)

    output:
	tuple val(meta_sample), val(meta_target), path("*_heatmap.png"), emit: heatmap

    script:
    def args = task.ext.args ?: ''
    def prefix_all = matrix_all.baseName
	def prefix_gain = matrix_gain.baseName
	def prefix_neut = matrix_neut.baseName
    """
    plotHeatmap \\
        -m ${matrix_all} \\
        -o ${prefix_all}_heatmap.png \\
        --dpi 200 \\
        --plotTitle "Sample: ${meta_sample.id} - Target: ${meta_target.name} - Type: ALL" \\
        $args
    plotHeatmap \\
        -m ${matrix_gain} \\
        -o ${prefix_gain}_heatmap.png \\
        --dpi 200 \\
        --plotTitle "Sample: ${meta_sample.id} - Target: ${meta_target.name} - Type: GAIN" \\
        $args
    plotHeatmap \\
        -m ${matrix_neut} \\
        -o ${prefix_neut}_heatmap.png \\
        --dpi 200 \\
        --plotTitle "Sample: ${meta_sample.id} - Target: ${meta_target.name} - Type: NEUT" \\
        $args
    """

    stub:
    def prefix_all = allbed.baseName
	def prefix_gain = gainbed.baseName
	def prefix_neut = neutbed.baseName
    """
    touch ${prefix_all}_heatmap.png
    touch ${prefix_gain}_heatmap.png
    touch ${prefix_neut}_heatmap.png
    """
}
process COMPUTEMATRIX {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true	

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 16
		memory = 32.GB
	}
	
	input:
	tuple val(meta_sample), val(meta_target), path(bw), path(gainbed), path(neutbed), path(allbed)
	
	output:
	tuple val(meta_sample), val(meta_target), path("*ALL_matrix.gz"), path("*GAIN_matrix.gz"), path("*NEUT_matrix.gz"), emit: matrix

	script:
    def args = task.ext.args ?: ''
    def prefix_all = allbed.baseName
	def prefix_gain = gainbed.baseName
	def prefix_neut = neutbed.baseName
	"""
	computeMatrix reference-point \\
        --referencePoint center \\
        -S ${bw} \\
        -R ${allbed} \\
        -a ${params.target_expand_sx} \\
        -b ${params.target_expand_dx} \\
        -o ${prefix_all}_matrix.gz \\
		--blackListFileName ${params.blacklist_bed} \\
        --numberOfProcessors ${task.cpus} \\
        $args
	computeMatrix reference-point \\
        --referencePoint center \\
        -S ${bw} \\
        -R ${gainbed} \\
        -a ${params.target_expand_sx} \\
        -b ${params.target_expand_dx} \\
        -o ${prefix_gain}_matrix.gz \\
		--blackListFileName ${params.blacklist_bed} \\
        --numberOfProcessors ${task.cpus} \\
        $args
	computeMatrix reference-point \\
        --referencePoint center \\
        -S ${bw} \\
        -R ${neutbed} \\
        -a ${params.target_expand_sx} \\
        -b ${params.target_expand_dx} \\
        -o ${prefix_neut}_matrix.gz \\
		--blackListFileName ${params.blacklist_bed} \\
        --numberOfProcessors ${task.cpus} \\
        $args
	"""

	stub:
	def prefix_all = allbed.baseName
	def prefix_gain = gainbed.baseName
	def prefix_neut = neutbed.baseName
	"""
	touch ${prefix_all}_matrix.gz
	touch ${prefix_gain}_matrix.gz
	touch ${prefix_neut}_matrix.gz
	"""
}
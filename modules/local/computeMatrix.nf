process COMPUTEMATRIX {
	conda '/home/davide.rambaldi/miniconda3/envs/deeptools'
    publishDir "${params.outdir}/${meta_sample.caseid}/${meta_sample.id}/fragmentomics/processed/matrix/${meta_target.source}/${meta_target.name}", mode:'copy', overwrite:true	
	label 'hpc_executor'

	if ( "${workflow.stubRun}" == "false" ) {
		cpus = 16
		memory = 32.GB
		time = '3h'
	}
	
	input:
	tuple val(meta_sample), val(meta_target), path(bw), path(bed)
	
	output:
	tuple val(meta_sample), val(meta_target), path("*_matrix.gz"), emit: matrix

	script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: bed.baseName
	"""
	computeMatrix reference-point \\
		--referencePoint center \\
		-S ${bw} \\
		-R ${bed} \\
		-a ${params.target_expand_sx} \\
		-b ${params.target_expand_dx} \\
		-o ${prefix}_matrix.gz \\
		--blackListFileName ${params.blacklist_bed} \\
		--numberOfProcessors ${task.cpus} \\
		$args
	"""

	stub:
	def prefix = task.ext.prefix ?: bed.baseName
	"""
	touch ${prefix}_matrix.gz
	"""
}